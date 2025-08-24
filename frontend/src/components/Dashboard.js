import React, { useState, useEffect } from 'react';
import { Card, Row, Col, ProgressBar } from 'react-bootstrap';

function Dashboard() {
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalProducts: 0,
    totalOrders: 0,
    revenue: 0
  });

  useEffect(() => {
    // Mock data for now - replace with actual API call
    setStats({
      totalUsers: 156,
      totalProducts: 89,
      totalOrders: 234,
      revenue: 45678.90
    });
  }, []);

  return (
    <div>
      <h2 className="mb-4">Dashboard</h2>
      
      <Row className="mb-4">
        <Col md={3}>
          <Card className="text-center">
            <Card.Body>
              <Card.Title>Total Users</Card.Title>
              <h3 className="text-primary">{stats.totalUsers}</h3>
              <ProgressBar now={75} className="mt-2" />
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center">
            <Card.Body>
              <Card.Title>Total Products</Card.Title>
              <h3 className="text-success">{stats.totalProducts}</h3>
              <ProgressBar now={60} className="mt-2" variant="success" />
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center">
            <Card.Body>
              <Card.Title>Total Orders</Card.Title>
              <h3 className="text-warning">{stats.totalOrders}</h3>
              <ProgressBar now={85} className="mt-2" variant="warning" />
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center">
            <Card.Body>
              <Card.Title>Revenue</Card.Title>
              <h3 className="text-info">${stats.revenue.toLocaleString()}</h3>
              <ProgressBar now={90} className="mt-2" variant="info" />
            </Card.Body>
          </Card>
        </Col>
      </Row>

      <Row>
        <Col md={6}>
          <Card>
            <Card.Header>
              <h5>Recent Activity</h5>
            </Card.Header>
            <Card.Body>
              <div className="d-flex justify-content-between mb-2">
                <span>New user registration</span>
                <small className="text-muted">2 minutes ago</small>
              </div>
              <div className="d-flex justify-content-between mb-2">
                <span>Order #1234 completed</span>
                <small className="text-muted">15 minutes ago</small>
              </div>
              <div className="d-flex justify-content-between mb-2">
                <span>New product added</span>
                <small className="text-muted">1 hour ago</small>
              </div>
              <div className="d-flex justify-content-between mb-2">
                <span>Payment received</span>
                <small className="text-muted">2 hours ago</small>
              </div>
            </Card.Body>
          </Card>
        </Col>
        <Col md={6}>
          <Card>
            <Card.Header>
              <h5>System Status</h5>
            </Card.Header>
            <Card.Body>
              <div className="d-flex justify-content-between mb-2">
                <span>User Service</span>
                <span className="badge bg-success">Healthy</span>
              </div>
              <div className="d-flex justify-content-between mb-2">
                <span>Product Service</span>
                <span className="badge bg-success">Healthy</span>
              </div>
              <div className="d-flex justify-content-between mb-2">
                <span>Order Service</span>
                <span className="badge bg-success">Healthy</span>
              </div>
              <div className="d-flex justify-content-between mb-2">
                <span>Database</span>
                <span className="badge bg-success">Healthy</span>
              </div>
              <div className="d-flex justify-content-between mb-2">
                <span>Load Balancer</span>
                <span className="badge bg-success">Healthy</span>
              </div>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </div>
  );
}

export default Dashboard;
