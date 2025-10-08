import React, { useEffect, useState } from "react";
import Health from "./components/Health.jsx";
import Logs from "./components/Logs.jsx";
import Docs from "./components/Docs.jsx";

const API_BASE = import.meta.env.VITE_API_BASE || "/api";
const COGNITO_DOMAIN = import.meta.env.VITE_COGNITO_DOMAIN || "<COGNITO_DOMAIN>";
const COGNITO_CLIENT_ID = import.meta.env.VITE_COGNITO_CLIENT_ID || "<CLIENT_ID>";

export default function App() {
  const [token, setToken] = useState(null);

  useEffect(() => {
    // capture Hosted UI redirect tokens
    if (window.location.hash) {
      const params = new URLSearchParams(window.location.hash.replace("#", ""));
      const idToken = params.get("id_token") || params.get("access_token");
      if (idToken) {
        localStorage.setItem("dp_token", idToken);
        setToken(idToken);
        // clean hash
        window.history.replaceState({}, document.title, "/");
      }
    } else {
      const t = localStorage.getItem("dp_token");
      if (t) setToken(t);
    }
  }, []);

  const login = () => {
    const redirect = encodeURIComponent(window.location.origin + "/");
    const url = `${COGNITO_DOMAIN}/oauth2/authorize?response_type=token&client_id=${COGNITO_CLIENT_ID}&redirect_uri=${redirect}&scope=openid+profile+email`;
    window.location.href = url;
  };

  const logout = () => {
    localStorage.removeItem("dp_token");
    setToken(null);
    // optional: call Cognito logout endpoint
    window.location.href = `${COGNITO_DOMAIN}/logout?client_id=${COGNITO_CLIENT_ID}&logout_uri=${encodeURIComponent(window.location.origin + "/")}`;
  };

  return (
    <>
      <header>
        <strong>Developer Portal</strong>
        <div>
          {token ? <button onClick={logout}>Sign out</button> : <button onClick={login}>Sign in</button>}
        </div>
      </header>

      <div className="container">
        <div className="card">
          <h3>Welcome</h3>
          <p style={{color:"#94a3b8"}}>Authenticate to see live ECS metrics, logs, and docs.</p>
        </div>

        <Health token={token} apiBase={API_BASE} />
        <Logs token={token} apiBase={API_BASE} />
        <Docs token={token} apiBase={API_BASE} />
      </div>
    </>
  );
}

