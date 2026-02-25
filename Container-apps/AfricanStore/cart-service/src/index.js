const express = require('express');
const cors = require('cors');
const cartRoutes = require('./routes/cart');

const app = express();
const PORT = process.env.PORT || 3003;

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'cart-service' });
});

// Routes
app.use('/api/cart', cartRoutes);

app.listen(PORT, () => {
  console.log(`Cart service running on port ${PORT}`);
});
