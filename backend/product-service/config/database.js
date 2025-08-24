const { Pool } = require('pg');

// Database configuration
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'eks_microservices',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'password',
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
  connectionTimeoutMillis: 2000, // Return an error after 2 seconds if connection could not be established
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
};

// Create connection pool
const pool = new Pool(dbConfig);

// Handle pool errors
pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

// Test database connection
const testConnection = async () => {
  try {
    const client = await pool.connect();
    console.log('✅ Database connection successful');
    client.release();
    return true;
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    return false;
  }
};

// Initialize database tables
const initTables = async () => {
  try {
    const client = await pool.connect();
    
    // Create products table
    await client.query(`
      CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        description TEXT,
        price DECIMAL(10,2) NOT NULL,
        stock_quantity INTEGER DEFAULT 0,
        category VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Insert sample products if table is empty
    const { rows } = await client.query('SELECT COUNT(*) FROM products');
    if (parseInt(rows[0].count) === 0) {
      await client.query(`
        INSERT INTO products (name, description, price, stock_quantity, category) VALUES 
        ('Sample Product 1', 'This is a sample product', 29.99, 100, 'electronics'),
        ('Sample Product 2', 'Another sample product', 49.99, 50, 'electronics')
      `);
      console.log('✅ Sample products inserted');
    }

    console.log('✅ Database tables initialized successfully');
    client.release();
  } catch (error) {
    console.error('❌ Failed to initialize database tables:', error);
    throw error;
  }
};

// Connect to database
const connectDB = async () => {
  try {
    await testConnection();
    await initTables();
    console.log('✅ Database setup completed');
  } catch (error) {
    console.error('❌ Database setup failed:', error);
    throw error;
  }
};

// Get database pool
const getPool = () => pool;

module.exports = {
  connectDB,
  getPool,
  testConnection,
  initTables
};
