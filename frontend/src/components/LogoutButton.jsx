// frontend/src/components/LogoutButton.jsx
import React from "react";

const COGNITO_DOMAIN = import.meta.env.VITE_COGNITO_DOMAIN;
const COGNITO_CLIENT_ID = import.meta.env.VITE_COGNITO_CLIENT_ID;

export default function LogoutButton() {
  const logout = () => {
    localStorage.removeItem("dp_token");
    const redirect = encodeURIComponent(window.location.origin + "/");
    window.location.href = `${COGNITO_DOMAIN}/logout?client_id=${COGNITO_CLIENT_ID}&logout_uri=${redirect}`;
  };

  return <button onClick={logout}>Sign out</button>;
}

