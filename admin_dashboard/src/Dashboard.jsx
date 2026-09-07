import { useEffect, useState } from "react";
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import API from "./api";

function Dashboard() {
  const [data, setData] = useState(null);
  const [salesData, setSalesData] = useState([]);
  const [ordersData, setOrdersData] = useState([]);
  const [salesmanData, setSalesmanData] = useState([]);
  const [productsData, setProductsData] = useState([]);
  const [error, setError] = useState("");

  useEffect(() => {
    const loadDashboard = async () => {
      try {
        const token = localStorage.getItem("admin_token");

        const response = await API.get("/api/dashboard/summary", {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        });

        setData(response.data);

        const salesResponse = await API.get(
          "/api/dashboard/sales-over-time",
          {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          }
        );

        setSalesData(salesResponse.data);

        const ordersResponse = await API.get(
          "/api/dashboard/orders-over-time",
          {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          }
        );

        setOrdersData(ordersResponse.data);
        const salesmanResponse = await API.get(
  "/api/dashboard/sales-by-salesman",
  {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  }
);

setSalesmanData(salesmanResponse.data);
const productsResponse = await API.get(
  "/api/dashboard/top-products",
  {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  }
);

setProductsData(productsResponse.data);
      } catch (err) {
        setError(
          err.response?.data?.detail || "Failed to load dashboard"
        );
      }
    };

    loadDashboard();
  }, []);

  if (error) {
    return <h2>{error}</h2>;
  }

  if (!data) {
    return <h2>Loading dashboard...</h2>;
  }

  return (
    <div className="dashboard">
      <h1>Admin Dashboard</h1>

      <div className="cards">
        <div className="card">
          <h3>Total Sales</h3>
          <p>₹{Number(data.total_sales).toLocaleString()}</p>
        </div>

        <div className="card">
          <h3>Total Orders</h3>
          <p>{data.total_orders}</p>
        </div>

        <div className="card">
          <h3>Total Customers</h3>
          <p>{data.total_customers}</p>
        </div>

        <div className="card">
          <h3>Total Salesmen</h3>
          <p>{data.total_salesmen}</p>
        </div>
      </div>

      <div className="chart-card">
        <h2>Sales Over Time</h2>

        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={salesData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" />
            <YAxis />
            <Tooltip />

            <Line
              type="monotone"
              dataKey="total_sales"
              stroke="#2563eb"
              strokeWidth={2}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>

      <div className="chart-card">
        <h2>Orders Over Time</h2>

        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={ordersData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" />
            <YAxis allowDecimals={false} />
            <Tooltip />

            <Line
              type="monotone"
              dataKey="total_orders"
              stroke="#16a34a"
              strokeWidth={2}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
      <div className="chart-card">
  <h2>Sales by Salesman</h2>

  <ResponsiveContainer width="100%" height={300}>
    <BarChart data={salesmanData}>
      <CartesianGrid strokeDasharray="3 3" />
      <XAxis dataKey="salesman_name" />
      <YAxis />
      <Tooltip />

      <Bar
        dataKey="total_sales"
        fill="#8884d8"
      />
    </BarChart>
  </ResponsiveContainer>
</div>
<div className="chart-card">
  <h2>Top Products</h2>

  <ResponsiveContainer width="100%" height={300}>
    <BarChart data={productsData}>
      <CartesianGrid strokeDasharray="3 3" />
      <XAxis dataKey="product_name" />
      <YAxis />
      <Tooltip />

      <Bar
        dataKey="total_quantity"
        fill="#82ca9d"
      />
    </BarChart>
  </ResponsiveContainer>
</div>
      <h2>Recent Orders</h2>

      <div className="orders">
        {data.recent_orders.length === 0 ? (
          <p>No orders yet.</p>
        ) : (
          data.recent_orders.map((order) => (
            <div className="order" key={order.id}>
              <strong>Order #{order.id}</strong>
              <span>Customer: {order.customer_id}</span>
              <span>Status: {order.status}</span>
              <span>
                ₹{Number(order.total_amount).toLocaleString()}
              </span>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

export default Dashboard;