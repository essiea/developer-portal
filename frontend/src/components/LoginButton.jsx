// frontend/src/components/LoginButton.jsx
import React from "react";

const COGNITO_DOMAIN = import.meta.env.VITE_COGNITO_DOMAIN;
const COGNITO_CLIENT_ID = import.meta.env.VITE_COGNITO_CLIENT_ID;

function base64URLEncode(str) {
  return btoa(String.fromCharCode(...new Uint8Array(str)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function sha256(buffer) {
  const digest = await crypto.subtle.digest("SHA-256", buffer);
  return new Uint8Array(digest);
}

export default function LoginButton() {
  const login = async () => {
    const codeVerifier = base64URLEncode(crypto.getRandomValues(new Uint8Array(32)));
    localStorage.setItem("pkce_code_verifier", codeVerifier);

    const encoder = new TextEncoder();
    const codeChallenge = base64URLEncode(await sha256(encoder.encode(codeVerifier)));

    const redirect = encodeURIComponent(window.location.origin + "/");
    const url = `${COGNITO_DOMAIN}/oauth2/authorize?response_type=code&client_id=${COGNITO_CLIENT_ID}&redirect_uri=${redirect}&scope=openid+profile+email&code_challenge_method=S256&code_challenge=${codeChallenge}`;
    window.location.href = url;
  };

  return <button onClick={login}>Sign in</button>;
}

