import React, { useEffect, useState } from "react";
import axios from "axios";

const DEFAULT_LOG_GROUP = "/ecs/devportal/backend"; // adjust to your log group

export default function Logs({ token, apiBase }) {
  const [logs, setLogs] = useState(null);
  const [loading, setLoading] = useState(false);

  const fetchLogs = () => {
    if (!token) return;
    setLoading(true);
    axios.get(`${apiBase}/logs?logGroup=${encodeURIComponent(DEFAULT_LOG_GROUP)}&limit=50`, {
      headers: { Authorization: `Bearer ${token}` }
    }).then(r => setLogs(r.data)).catch(console.error).finally(() => setLoading(false));
  };

  useEffect(() => { if (token) fetchLogs(); }, [token]);

  return (
    <div className="card">
      <h3>Recent Logs</h3>
      {!token ? <p>Sign in to view logs</p> :
        loading ? <p>Loading logs...</p> :
        <pre>{logs ? JSON.stringify(logs, null, 2) : "No logs"}</pre>}
      <div style={{marginTop:8}}>
        <button onClick={fetchLogs}>Refresh</button>
      </div>
    </div>
  );
}

