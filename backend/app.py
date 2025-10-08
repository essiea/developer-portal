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
@app.get("/app/health")
def health():
    return {"status": "ok"}

