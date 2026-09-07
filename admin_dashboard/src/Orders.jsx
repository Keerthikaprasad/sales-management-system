import { useEffect, useState } from "react";
import API from "./api";

function Orders() {
  const [orders, setOrders] = useState([]);
  const [status, setStatus] = useState("");
  const [search, setSearch] = useState("");
  const [minAmount, setMinAmount] = useState("");
  const [maxAmount, setMaxAmount] = useState("");
  const [error, setError] = useState("");
  const [selectedOrder, setSelectedOrder] = useState(null);

  // Load all admin orders
  const loadOrders = async () => {
    try {
      const token = localStorage.getItem("admin_token");

      const response = await API.get("/api/orders/admin/all", {
        params: status ? { status_filter: status } : {},
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      setOrders(response.data);
      setError("");
    } catch (err) {
      setError(
        err.response?.data?.detail || "Failed to load orders"
      );
    }
  };

  // Reload orders when status changes
  useEffect(() => {
    loadOrders();
  }, [status]);

  // Update order status
  const updateStatus = async (orderId, newStatus) => {
    try {
      const token = localStorage.getItem("admin_token");

      await API.patch(
        `/api/orders/admin/${orderId}/status`,
        { status: newStatus },
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      loadOrders();

      if (selectedOrder && selectedOrder.id === orderId) {
        setSelectedOrder({
          ...selectedOrder,
          status: newStatus,
        });
      }
    } catch (err) {
      setError(
        err.response?.data?.detail || "Failed to update status"
      );
    }
  };

  // Filter orders
  const filteredOrders = orders.filter((order) => {
    const text = search.toLowerCase();

    const matchesSearch =
      order.id.toString().includes(text) ||
      order.customer_name?.toLowerCase().includes(text) ||
      order.salesman_name?.toLowerCase().includes(text);

    const amount = Number(order.total_amount);

    const matchesMinAmount =
      minAmount === "" || amount >= Number(minAmount);

    const matchesMaxAmount =
      maxAmount === "" || amount <= Number(maxAmount);

    return (
      matchesSearch &&
      matchesMinAmount &&
      matchesMaxAmount
    );
  });

  // Format date
  const formatDate = (date) => {
    if (!date) return "N/A";

    return new Date(date).toLocaleString();
  };

  return (
    <div className="dashboard">
      <h1>Orders</h1>

      {/* Search and Filters */}
      <div className="order-controls">

        <input
          type="text"
          placeholder="Search by order, customer or salesman..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />

        <select
          value={status}
          onChange={(e) => setStatus(e.target.value)}
        >
          <option value="">All Orders</option>
          <option value="pending">Pending</option>
          <option value="confirmed">Confirmed</option>
          <option value="shipped">Shipped</option>
          <option value="delivered">Delivered</option>
          <option value="cancelled">Cancelled</option>
        </select>

        <input
          type="number"
          placeholder="Min amount"
          value={minAmount}
          onChange={(e) => setMinAmount(e.target.value)}
        />

        <input
          type="number"
          placeholder="Max amount"
          value={maxAmount}
          onChange={(e) => setMaxAmount(e.target.value)}
        />

      </div>

      {/* Error */}
      {error && (
        <p style={{ color: "red" }}>
          {error}
        </p>
      )}

      {/* Orders Table */}
      <div className="orders-table">
        <table>

          <thead>
            <tr>
              <th>Order</th>
              <th>Customer</th>
              <th>Salesman</th>
              <th>Total</th>
              <th>Status</th>
              <th>Update Status</th>
              <th>Details</th>
            </tr>
          </thead>

          <tbody>

            {filteredOrders.length === 0 ? (
              <tr>
                <td colSpan="7">
                  No orders found.
                </td>
              </tr>
            ) : (

              filteredOrders.map((order) => (
                <tr key={order.id}>

                  {/* Order ID */}
                  <td>
                    <strong>#{order.id}</strong>
                  </td>

                  {/* Customer */}
                  <td>
                    {order.customer_name || "Unknown"}
                  </td>

                  {/* Salesman */}
                  <td>
                    {order.salesman_name || "Unknown"}
                  </td>

                  {/* Total */}
                  <td>
                    ₹{Number(order.total_amount).toLocaleString()}
                  </td>

                  {/* Current Status */}
                  <td>
                    {order.status}
                  </td>

                  {/* Update Status */}
                  <td>
                    <select
                      value={order.status}
                      onChange={(e) =>
                        updateStatus(
                          order.id,
                          e.target.value
                        )
                      }
                    >
                      <option value="pending">
                        Pending
                      </option>

                      <option value="confirmed">
                        Confirmed
                      </option>

                      <option value="shipped">
                        Shipped
                      </option>

                      <option value="delivered">
                        Delivered
                      </option>

                      <option value="cancelled">
                        Cancelled
                      </option>
                    </select>
                  </td>

                  {/* View Details */}
                  <td>
                    <button
                      onClick={() => setSelectedOrder(order)}
                    >
                      View
                    </button>
                  </td>

                </tr>
              ))

            )}

          </tbody>

        </table>
      </div>

      {/* Order Details Modal */}
      {selectedOrder && (
        <div className="modal-overlay">

          <div className="order-modal">

            {/* Header */}
            <div className="modal-header">

              <h2>
                Order #{selectedOrder.id}
              </h2>

              <button
                className="close-button"
                onClick={() => setSelectedOrder(null)}
              >
                ✕
              </button>

            </div>

            {/* Order Information */}
            <div className="order-info">

              <div>
                <strong>Customer</strong>
                <p>
                  {selectedOrder.customer_name ||
                    `Customer #${selectedOrder.customer_id}`}
                </p>
              </div>

              <div>
                <strong>Salesman</strong>
                <p>
                  {selectedOrder.salesman_name ||
                    `Salesman #${selectedOrder.salesman_id}`}
                </p>
              </div>

              <div>
                <strong>Status</strong>
                <p>
                  {selectedOrder.status}
                </p>
              </div>

              <div>
                <strong>Order Date</strong>
                <p>
                  {formatDate(selectedOrder.created_at)}
                </p>
              </div>

            </div>

            {/* Order Items */}
            <h3>Order Items</h3>

            <div className="order-items">

              <table>

                <thead>
                  <tr>
                    <th>Product</th>
                    <th>Quantity</th>
                    <th>Unit Price</th>
                    <th>Subtotal</th>
                  </tr>
                </thead>

                <tbody>

                  {selectedOrder.items?.map((item) => (
                    <tr key={item.id}>

                      <td>
                        {item.product_name ||
                          `Product #${item.product_id}`}
                      </td>

                      <td>
                        {item.quantity}
                      </td>

                      <td>
                        ₹
                        {Number(
                          item.unit_price
                        ).toLocaleString()}
                      </td>

                      <td>
                        ₹
                        {Number(
                          item.subtotal
                        ).toLocaleString()}
                      </td>

                    </tr>
                  ))}

                </tbody>

              </table>

            </div>

            {/* Total */}
            <div className="order-total">

              <strong>
                Total Amount
              </strong>

              <strong>
                ₹
                {Number(
                  selectedOrder.total_amount
                ).toLocaleString()}
              </strong>

            </div>

            {/* Close */}
            <div className="modal-footer">

              <button
                onClick={() => setSelectedOrder(null)}
              >
                Close
              </button>

            </div>

          </div>

        </div>
      )}

    </div>
  );
}

export default Orders;