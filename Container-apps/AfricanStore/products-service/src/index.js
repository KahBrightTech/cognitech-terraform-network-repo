const express = require('express');
const cors = require('cors');
const productsRoutes = require('./routes/products');
const categoriesRoutes = require('./routes/categories');

const app = express();
const PORT = process.env.PORT || 3002;

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'products-service' });
});

// Routes
app.use('/api/products', productsRoutes);
app.use('/api/categories', categoriesRoutes);

app.listen(PORT, () => {
  console.log(`Products service running on port ${PORT}`);
});
