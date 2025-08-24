import React, { useState, useEffect } from 'react';
import { Card, Table, Button, Modal, Form } from 'react-bootstrap';

function Products() {
  const [products, setProducts] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({ name: '', price: '', category: 'electronics' });

  useEffect(() => {
    // Mock data for now - replace with actual API call
    setProducts([
      { id: 1, name: 'Laptop', price: 999.99, category: 'electronics' },
      { id: 2, name: 'Smartphone', price: 599.99, category: 'electronics' },
      { id: 3, name: 'Headphones', price: 199.99, category: 'electronics' }
    ]);
  }, []);

  const handleSubmit = (e) => {
    e.preventDefault();
    const newProduct = { id: products.length + 1, ...formData };
    setProducts([...products, newProduct]);
    setFormData({ name: '', price: '', category: 'electronics' });
    setShowModal(false);
  };

  return (
    <div>
      <div className="d-flex justify-content-between align-items-center mb-3">
        <h2>Products Management</h2>
        <Button variant="primary" onClick={() => setShowModal(true)}>
          Add Product
        </Button>
      </div>

      <Card>
        <Card.Body>
          <Table striped bordered hover>
            <thead>
              <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Price</th>
                <th>Category</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {products.map(product => (
                <tr key={product.id}>
                  <td>{product.id}</td>
                  <td>{product.name}</td>
                  <td>${product.price}</td>
                  <td>{product.category}</td>
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
          <Modal.Title>Add New Product</Modal.Title>
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
              <Form.Label>Price</Form.Label>
              <Form.Control
                type="number"
                step="0.01"
                value={formData.price}
                onChange={(e) => setFormData({...formData, price: e.target.value})}
                required
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Category</Form.Label>
              <Form.Select
                value={formData.category}
                onChange={(e) => setFormData({...formData, category: e.target.value})}
              >
                <option value="electronics">Electronics</option>
                <option value="clothing">Clothing</option>
                <option value="books">Books</option>
                <option value="home">Home & Garden</option>
              </Form.Select>
            </Form.Group>
            <Button variant="primary" type="submit">
              Add Product
            </Button>
          </Form>
        </Modal.Body>
      </Modal>
    </div>
  );
}

export default Products;
