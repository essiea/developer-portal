import os, time
from typing import Optional
from fastapi import FastAPI, Header, HTTPException, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
import boto3
import requests
from jose import jwt, JWTError
from datetime import datetime, timedelta

app = FastAPI(title="DevPortal API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ALB/Cognito handle auth; keep CORS simple for local/dev
    allow_methods=["*"],
    allow_headers=["*"],
)

REGION = os.getenv("AWS_REGION", "us-east-1")
CLUSTER = os.getenv("ECS_CLUSTER_NAME", "developer-portal-cluster")
DOCS_BUCKET = os.getenv("DOCS_BUCKET")
COGNITO_POOL_ID = os.getenv("COGNITO_POOL_ID")
COGNITO_CLIENT_ID = os.getenv("COGNITO_CLIENT_ID")
COGNITO_ISSUER = f"https://cognito-idp.{REGION}.amazonaws.com/{COGNITO_POOL_ID}" if COGNITO_POOL_ID else None
JWKS_URL = f"{COGNITO_ISSUER}/.well-known/jwks.json" if COGNITO_POOL_ID else None

ecs = boto3.client("ecs", region_name=REGION)
logs = boto3.client("logs", region_name=REGION)
s3 = boto3.client("s3", region_name=REGION)
cw = boto3.client("cloudwatch", region_name=REGION)

JWKS = None

def fetch_jwks():
    global JWKS
    if JWKS is None and JWKS_URL:
        r = requests.get(JWKS_URL, timeout=5)
        r.raise_for_status()
        JWKS = r.json()
    return JWKS

def verify_token(token: str):
    if not COGNITO_POOL_ID or not COGNITO_CLIENT_ID:
        raise HTTPException(status_code=500, detail="Cognito not configured")
    try:
        jwks = fetch_jwks()
        unverified = jwt.get_unverified_header(token)
        kid = unverified.get("kid")
        key = next((k for k in jwks["keys"] if k["kid"] == kid), None)
        if not key:
            raise HTTPException(status_code=401, detail="Unknown token key")
        public_key = jwt.construct_rsa_key(key)
        claims = jwt.decode(
            token,
            public_key,
            algorithms=["RS256"],
            audience=COGNITO_CLIENT_ID,
            issuer=COGNITO_ISSUER
        )
        return claims
    except JWTError as e:
        raise HTTPException(status_code=401, detail=f"Token error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))

def auth_required(authorization: Optional[str] = Header(None)):
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing Authorization header")
    parts = authorization.split()
    token = parts[1] if len(parts) == 2 else parts[0]
    return verify_token(token)

# ✅ Root health check
@app.get("/")
def root():
    return {"status": "ok"}

# ✅ Explicit health check
@app.get("/api/health")
def health():
    return {"status": "ok"}

# ✅ ECS Service Metrics (CPU/Memory)
@app.get("/api/metrics")
def metrics(service: str, user=Depends(auth_required)):
    now = datetime.utcnow()
    start = now - timedelta(minutes=60)

    metrics = {}
    for metric_name in ["CPUUtilization", "MemoryUtilization"]:
        resp = cw.get_metric_statistics(
            Namespace="AWS/ECS",
            MetricName=metric_name,
            Dimensions=[
                {"Name": "ClusterName", "Value": CLUSTER},
                {"Name": "ServiceName", "Value": service},
            ],
            StartTime=start,
            EndTime=now,
            Period=60,
            Statistics=["Average"]
        )
        datapoints = sorted(resp["Datapoints"], key=lambda x: x["Timestamp"])
        metrics[metric_name] = [d["Average"] for d in datapoints]

    return metrics

# ✅ ECS Logs (last 20 lines)
@app.get("/api/logs")
def get_logs(service: str, user=Depends(auth_required)):
    log_group = f"/ecs/{service}"
    try:
        streams = logs.describe_log_streams(
            logGroupName=log_group,
            orderBy="LastEventTime",
            descending=True,
            limit=1
        )
        if not streams["logStreams"]:
            return {"logs": []}

        stream_name = streams["logStreams"][0]["logStreamName"]

        events = logs.get_log_events(
            logGroupName=log_group,
            logStreamName=stream_name,
            limit=20,
            startFromHead=False
        )
        lines = [e["message"] for e in events["events"]]
        return {"logs": lines}
    except logs.exceptions.ResourceNotFoundException:
        return {"logs": []}

