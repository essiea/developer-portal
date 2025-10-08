import React, { useEffect, useState } from "react";
import Health from "./components/Health.jsx";
import Logs from "./components/Logs.jsx";
import Docs from "./components/Docs.jsx";

const API_BASE = import.meta.env.VITE_API_BASE || "/api";
const COGNITO_DOMAIN = import.meta.env.VITE_COGNITO_DOMAIN || "<COGNITO_DOMAIN>";
const COGNITO_CLIENT_ID = import.meta.env.VITE_COGNITO_CLIENT_ID || "<CLIENT_ID>";

export default function App() {
  const [token, setToken] = useState(null);

  // --- Token Refresh Helper ---
  async function refreshToken() {
    const refresh = localStorage.getItem("dp_refresh_token");
    if (!refresh) return null;

    const redirect = window.location.origin + "/";
    const body = new URLSearchParams({
      grant_type: "refresh_token",
      client_id: COGNITO_CLIENT_ID,
      redirect_uri: redirect,
      refresh_token: refresh,
    });

    const res = await fetch(`${COGNITO_DOMAIN}/oauth2/token`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body,
    });

    const data = await res.json();

    if (data.id_token) {
      const now = Date.now();
      const expiryTime = now + data.expires_in * 1000;

      localStorage.setItem("dp_id_token", data.id_token);
      localStorage.setItem("dp_access_token", data.access_token);
      localStorage.setItem("dp_expiry", expiryTime);

      return data.id_token;
    }
    return null;
  }

  // --- On Load: Capture tokens from URL or localStorage ---
  useEffect(() => {
    const captureTokens = async () => {
      if (window.location.hash) {
        // Handle implicit flow (#id_token=... style)
        const params = new URLSearchParams(window.location.hash.replace("#", ""));
        const idToken = params.get("id_token") || params.get("access_token");
        const refresh = params.get("refresh_token");
        const expiresIn = params.get("expires_in");

        if (idToken) {
          const now = Date.now();
          const expiryTime = expiresIn ? now + parseInt(expiresIn) * 1000 : now + 3600 * 1000;

          localStorage.setItem("dp_id_token", idToken);
          localStorage.setItem("dp_access_token", idToken); // for APIs if needed
          if (refresh) localStorage.setItem("dp_refresh_token", refresh);
          localStorage.setItem("dp_expiry", expiryTime);

          setToken(idToken);
          window.history.replaceState({}, document.title, "/");
        }
      } else {
        // Load existing token
        const expiry = localStorage.getItem("dp_expiry");
        const storedToken = localStorage.getItem("dp_id_token");
        const now = Date.now();

        if (expiry && now > expiry - 60000) {
          const newToken = await refreshToken();
          if (newToken) setToken(newToken);
          else {
            localStorage.clear();
            setToken(null);
          }
        } else if (storedToken) {
          setToken(storedToken);
        }
      }
    };

    captureTokens();
    const interval = setInterval(captureTokens, 60000); // check every 1 min
    return () => clearInterval(interval);
  }, []);

  // --- Login and Logout ---
  const login = () => {
    const redirect = encodeURIComponent(window.location.origin + "/");
    const url = `${COGNITO_DOMAIN}/oauth2/authorize?response_type=token&client_id=${COGNITO_CLIENT_ID}&redirect_uri=${redirect}&scope=openid+profile+email`;
    window.location.href = url;
  };

  const logout = () => {
    localStorage.removeItem("dp_id_token");
    localStorage.removeItem("dp_access_token");
    localStorage.removeItem("dp_refresh_token");
    localStorage.removeItem("dp_expiry");
    setToken(null);

    window.location.href = `${COGNITO_DOMAIN}/logout?client_id=${COGNITO_CLIENT_ID}&logout_uri=${encodeURIComponent(
      window.location.origin + "/"
    )}`;
  };

  // --- Render ---
  return (
    <>
      <header>
        <strong>Developer Portal</strong>
        <div>
          {token ? (
            <button onClick={logout}>Sign out</button>
          ) : (
            <button onClick={login}>Sign in</button>
          )}
        </div>
      </header>

      <div className="container">
        <div className="card">
          <h3>Welcome</h3>
          <p style={{ color: "#94a3b8" }}>
            Authenticate to see live ECS metrics, logs, and docs.
          </p>
        </div>

        <Health token={token} apiBase={API_BASE} />
        <Logs token={token} apiBase={API_BASE} />
        <Docs token={token} apiBase={API_BASE} />
      </div>
    </>
  );
}

