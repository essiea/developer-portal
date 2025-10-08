import React, { useEffect, useState } from "react";
import axios from "axios";
import { LineChart, Line, XAxis, YAxis, Tooltip, CartesianGrid, ResponsiveContainer } from "recharts";

export default function Health({ token, apiBase }) {
  const [cpu, setCpu] = useState([]);
  const [mem, setMem] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!token) return;
    setLoading(true);
    axios.get(`${apiBase}/metrics?cluster=devportal-cluster&service=devportal-backend&minutes=60`, {
      headers: { Authorization: `Bearer ${token}` }
    }).then(r => {
      setCpu(r.data.cpu || []);
      setMem(r.data.memory || []);
    }).catch(console.error).finally(() => setLoading(false));
  }, [token, apiBase]);

  const formatX = (v) => (v.includes("T") ? v.split("T")[1].slice(0,5) : v);

  return (
    <div className="card">
      <h3>Service Metrics (last 60 min)</h3>
      {!token ? <p>Sign in to view metrics</p> : loading ? <p>Loading...</p> : (
        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:16}}>
          <div style={{height:240}}>
            <h4>CPU Utilization (%)</h4>
            <ResponsiveContainer>
              <LineChart data={cpu}>
                <XAxis dataKey="t" tickFormatter={formatX} />
                <YAxis domain={[0, 'dataMax + 10']} />
                <Tooltip />
                <CartesianGrid strokeDasharray="3 3" />
                <Line type="monotone" dataKey="v" dot={false} />
              </LineChart>
            </ResponsiveContainer>
          </div>
          <div style={{height:240}}>
            <h4>Memory Utilization (%)</h4>
            <ResponsiveContainer>
              <LineChart data={mem}>
                <XAxis dataKey="t" tickFormatter={formatX} />
                <YAxis domain={[0, 'dataMax + 10']} />
                <Tooltip />
                <CartesianGrid strokeDasharray="3 3" />
                <Line type="monotone" dataKey="v" dot={false} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}
    </div>
  );
}

