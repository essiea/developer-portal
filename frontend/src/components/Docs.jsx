import React, { useEffect, useState } from "react";
import axios from "axios";

export default function Docs({ token, apiBase }) {
  const [text, setText] = useState("Loading...");

  useEffect(() => {
    if (!token) return;
    axios.get(`${apiBase}/docs/README.md`, {
      headers: { Authorization: `Bearer ${token}` }
    }).then(r => setText(r.data.content)).catch(() => setText("No docs or access denied"));
  }, [token, apiBase]);

  return (
    <div className="card">
      <h3>Docs (README.md)</h3>
      <pre>{text}</pre>
    </div>
  );
}

