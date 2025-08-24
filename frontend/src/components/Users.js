import React, { useState, useEffect } from 'react';
import { Card, Table, Button, Modal, Form } from 'react-bootstrap';

function Users() {
  const [users, setUsers] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({ name: '', email: '', role: 'user' });

  useEffect(() => {
    // Mock data for now - replace with actual API call
    setUsers([
      { id: 1, name: 'John Doe', email: 'john@example.com', role: 'admin' },
      { id: 2, name: 'Jane Smith', email: 'jane@example.com', role: 'user' },
      { id: 3, name: 'Bob Johnson', email: 'bob@example.com', role: 'user' }
    ]);
  }, []);

  const handleSubmit = (e) => {
    e.preventDefault();
    const newUser = { id: users.length + 1, ...formData };
    setUsers([...users, newUser]);
    setFormData({ name: '', email: '', role: 'user' });
    setShowModal(false);
  };

  return (
    <div>
      <div className="d-flex justify-content-between align-items-center mb-3">
        <h2>Users Management</h2>
        <Button variant="primary" onClick={() => setShowModal(true)}>
          Add User
        </Button>
      </div>

      <Card>
        <Card.Body>
          <Table striped bordered hover>
            <thead>
              <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Email</th>
                <th>Role</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {users.map(user => (
                <tr key={user.id}>
                  <td>{user.id}</td>
                  <td>{user.name}</td>
                  <td>{user.email}</td>
                  <td>{user.role}</td>
                  <td>
                    <Button variant="outline-primary" size="sm" className="me-2">Edit</Button>
                    <Button variant="outline-danger" size="sm">Delete</Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </Table>
        </Card.Body>
      </Card>

      <Modal show={showModal} onHide={() => setShowModal(false)}>
        <Modal.Header closeButton>
          <Modal.Title>Add New User</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form onSubmit={handleSubmit}>
            <Form.Group className="mb-3">
              <Form.Label>Name</Form.Label>
              <Form.Control
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({...formData, name: e.target.value})}
                required
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Email</Form.Label>
              <Form.Control
                type="email"
                value={formData.email}
                onChange={(e) => setFormData({...formData, email: e.target.value})}
                required
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Role</Form.Label>
              <Form.Select
                value={formData.role}
                onChange={(e) => setFormData({...formData, role: e.target.value})}
              >
                <option value="user">User</option>
                <option value="admin">Admin</option>
              </Form.Select>
            </Form.Group>
            <Button variant="primary" type="submit">
              Add User
            </Button>
          </Form>
        </Modal.Body>
      </Modal>
    </div>
  );
}

export default Users;
