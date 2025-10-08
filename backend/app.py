import os, time
from typing import Optional
from fastapi import FastAPI, Header, HTTPException, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
import boto3
import requests
from jose import jwt, JWTError

app = FastAPI(title="DevPortal API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ALB/Cognito handle auth; keep CORS simple for local/dev
    allow_methods=["*"],
    allow_headers=["*"],
)

REGION = os.getenv("AWS_REGION", "us-east-1")
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
    if JWKS is None:
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
        if not key: raise HTTPException(status_code=401, detail="Unknown token key")
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

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/api/metrics")
def metrics(
    cluster: str = Query(...),
    service: str = Query(...),
    minutes: int = Query(60, ge=5, le=1440),
    claims=Depends(auth_required),
):
    end = int(time.time())
    start = end - minutes * 60

    def q(metric_name, qid):
        return {
            "Id": qid,
            "MetricStat": {
                "Metric": {
                    "Namespace": "AWS/ECS",
                    "MetricName": metric_name,
                    "Dimensions": [
                        {"Name": "ClusterName", "Value": cluster},
                        {"Name": "ServiceName", "Value": service},
                    ],
                },
                "Period": 60,
                "Stat": "Average",
            },
            "ReturnData": True,
        }

    resp = cw.get_metric_data(
        MetricDataQueries=[q("CPUUtilization", "cpu"), q("MemoryUtilization", "mem")],
        StartTime=start,
        EndTime=end,
        ScanBy="TimestampDescending",
        MaxDatapoints=1000,
    )

    def to_series(item_id):
        pts = []
        for t, v in zip(
            next(m["Timestamps"] for m in resp["MetricDataResults"] if m["Id"] == item_id),
            next(m["Values"] for m in resp["MetricDataResults"] if m["Id"] == item_id),
        ):
            pts.append({"t": t.isoformat(), "v": v})
        return sorted(pts, key=lambda x: x["t"])

    return {"cpu": to_series("cpu"), "memory": to_series("mem")}

@app.get("/api/logs")
def get_logs(
    logGroup: str = Query(..., alias="logGroup"),
    limit: int = Query(50, ge=1, le=200),
    claims=Depends(auth_required),
):
    end = int(time.time())
    start = end - 3600
    query = f"fields @timestamp, @message | sort @timestamp desc | limit {limit}"
    q = logs.start_query(logGroupName=logGroup, startTime=start, endTime=end, queryString=query)
    qid = q["queryId"]
    for _ in range(12):
        r = logs.get_query_results(queryId=qid)
        if r["status"] in ("Complete", "Failed", "Cancelled"):
            return r
        time.sleep(0.5)
    return {"status": "Timeout", "queryId": qid}

@app.get("/api/docs/{key:path}")
def get_doc(key: str, claims=Depends(auth_required)):
    if not DOCS_BUCKET:
        raise HTTPException(status_code=500, detail="DOCS_BUCKET not set")
    try:
        obj = s3.get_object(Bucket=DOCS_BUCKET, Key=key)
        return {"content": obj["Body"].read().decode("utf-8")}
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

