import React from 'react';
import { Card, Row, Col, Button } from 'react-bootstrap';

const Home = () => {
  return (
    <div>
      <h1 className="mb-4">Welcome to EKS Microservices WebApp</h1>
      
      <Row className="mb-4">
        <Col>
          <Card className="text-center">
            <Card.Body>
              <Card.Title>🚀 Modern Microservices Architecture</Card.Title>
              <Card.Text>
                Built with React, Node.js, and deployed on AWS EKS with full CI/CD pipeline
              </Card.Text>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      <Row className="mb-4">
        <Col md={4}>
          <Card className="h-100">
            <Card.Body>
              <Card.Title>👥 User Management</Card.Title>
              <Card.Text>
                Manage user accounts, authentication, and authorization
              </Card.Text>
              <Button href="/users" variant="primary">Go to Users</Button>
            </Card.Body>
          </Card>
        </Col>
        
        <Col md={4}>
          <Card className="h-100">
            <Card.Body>
              <Card.Title>📦 Product Catalog</Card.Title>
              <Card.Text>
                Browse and manage product inventory and catalog
              </Card.Text>
              <Button href="/products" variant="primary">Go to Products</Button>
            </Card.Body>
          </Card>
        </Col>
        
        <Col md={4}>
          <Card className="h-100">
            <Card.Body>
              <Card.Title>🛒 Order Management</Card.Title>
              <Card.Text>
                Process orders, track status, and manage fulfillment
              </Card.Text>
              <Button href="/orders" variant="primary">Go to Orders</Button>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      <Row>
        <Col md={6}>
          <Card className="h-100">
            <Card.Body>
              <Card.Title>📊 Dashboard & Analytics</Card.Title>
              <Card.Text>
                Real-time metrics, monitoring, and business intelligence
              </Card.Text>
              <Button href="/dashboard" variant="success">View Dashboard</Button>
            </Card.Body>
          </Card>
        </Col>
        
        <Col md={6}>
          <Card className="h-100">
            <Card.Body>
              <Card.Title>🔧 DevOps & Monitoring</Card.Title>
              <Card.Text>
                Jenkins CI/CD, ArgoCD GitOps, Prometheus, Grafana, and Splunk
              </Card.Text>
              <Button href="/dashboard" variant="info">View Metrics</Button>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </div>
  );
};

export default Home;
