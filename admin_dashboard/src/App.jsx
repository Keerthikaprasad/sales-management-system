import { useState } from "react";
import API from "./api";
import Dashboard from "./Dashboard";
import Orders from "./Orders";

function App() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loggedIn, setLoggedIn] = useState(
    !!localStorage.getItem("admin_token")
  );
  const [page, setPage] = useState("dashboard");

  const handleLogin = async (e) => {
    e.preventDefault();
    setError("");

    try {
      const formData = new URLSearchParams();

      formData.append("username", email);
      formData.append("password", password);

      const response = await API.post(
        "/api/auth/login",
        formData,
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        }
      );

      localStorage.setItem(
        "admin_token",
        response.data.access_token
      );

      setLoggedIn(true);
      setPage("dashboard");
    } catch (err) {
      setError(
        err.response?.data?.detail || "Login failed"
      );
    }
  };

  const handleLogout = () => {
    localStorage.removeItem("admin_token");
    setLoggedIn(false);
  };

  if (!loggedIn) {
    return (
      <div className="login-container">
        <div className="login-box">
          <h1>Sales Management</h1>
          <h2>Admin Login</h2>

          <form onSubmit={handleLogin}>
            <input
              type="email"
              placeholder="Admin Email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />

            <input
              type="password"
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />

            {error && (
              <p style={{ color: "red" }}>{error}</p>
            )}

            <button type="submit">Login</button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <>
      <nav className="navbar">
        <div>
          <strong>Sales Management</strong>
        </div>

        <div className="nav-buttons">
          <button onClick={() => setPage("dashboard")}>
            Dashboard
          </button>

          <button onClick={() => setPage("orders")}>
            Orders
          </button>

          <button onClick={handleLogout}>
            Logout
          </button>
        </div>
      </nav>

      {page === "dashboard" && <Dashboard />}

      {page === "orders" && <Orders />}
    </>
  );
}

export default App;