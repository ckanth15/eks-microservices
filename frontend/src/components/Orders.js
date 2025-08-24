import React, { useState, useEffect } from 'react';
import { Card, Table, Button, Modal, Form } from 'react-bootstrap';

function Orders() {
  const [orders, setOrders] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({ customerId: '', productId: '', quantity: 1, status: 'pending' });

  useEffect(() => {
    // Mock data for now - replace with actual API call
    setOrders([
      { id: 1, customerId: 'C001', productId: 'P001', quantity: 2, status: 'completed', total: 1999.98 },
      { id: 2, customerId: 'C002', productId: 'P002', quantity: 1, status: 'pending', total: 599.99 },
      { id: 3, customerId: 'C003', productId: 'P003', quantity: 3, status: 'processing', total: 599.97 }
    ]);
  }, []);

  const handleSubmit = (e) => {
    e.preventDefault();
    const newOrder = { id: orders.length + 1, ...formData, total: 0 };
    setOrders([...orders, newOrder]);
    setFormData({ customerId: '', productId: '', quantity: 1, status: 'pending' });
    setShowModal(false);
  };

  return (
    <div>
      <div className="d-flex justify-content-between align-items-center mb-3">
        <h2>Orders Management</h2>
        <Button variant="primary" onClick={() => setShowModal(true)}>
          Create Order
        </Button>
      </div>

      <Card>
        <Card.Body>
          <Table striped bordered hover>
            <thead>
              <tr>
                <th>ID</th>
                <th>Customer ID</th>
                <th>Product ID</th>
                <th>Quantity</th>
                <th>Status</th>
                <th>Total</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {orders.map(order => (
                <tr key={order.id}>
                  <td>{order.id}</td>
                  <td>{order.customerId}</td>
                  <td>{order.productId}</td>
                  <td>{order.quantity}</td>
                  <td>
                    <span className={`badge bg-${order.status === 'completed' ? 'success' : order.status === 'pending' ? 'warning' : 'info'}`}>
                      {order.status}
                    </span>
                  </td>
                  <td>${order.total}</td>
                  <td>
                    <Button variant="outline-primary" size="sm" className="me-2">Edit</Button>
                    <Button variant="outline-danger" size="sm">Cancel</Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </Table>
        </Card.Body>
      </Card>

      <Modal show={showModal} onHide={() => setShowModal(false)}>
        <Modal.Header closeButton>
          <Modal.Title>Create New Order</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form onSubmit={handleSubmit}>
            <Form.Group className="mb-3">
              <Form.Label>Customer ID</Form.Label>
              <Form.Control
                type="text"
                value={formData.customerId}
                onChange={(e) => setFormData({...formData, customerId: e.target.value})}
                required
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Product ID</Form.Label>
              <Form.Control
                type="text"
                value={formData.productId}
                onChange={(e) => setFormData({...formData, productId: e.target.value})}
                required
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Quantity</Form.Label>
              <Form.Control
                type="number"
                min="1"
                value={formData.quantity}
                onChange={(e) => setFormData({...formData, quantity: parseInt(e.target.value)})}
                required
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Status</Form.Label>
              <Form.Select
                value={formData.status}
                onChange={(e) => setFormData({...formData, status: e.target.value})}
              >
                <option value="pending">Pending</option>
                <option value="processing">Processing</option>
                <option value="completed">Completed</option>
                <option value="cancelled">Cancelled</option>
              </Form.Select>
            </Form.Group>
            <Button variant="primary" type="submit">
              Create Order
            </Button>
          </Form>
        </Modal.Body>
      </Modal>
    </div>
  );
}

export default Orders;
