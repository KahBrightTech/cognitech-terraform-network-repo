const express = require('express');
const db = require('../config/database');
const authenticateUser = require('../middleware/auth');

const router = express.Router();

// Get user's cart
router.get('/', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;

    // Get or create cart
    let cartResult = await db.query(
      'SELECT id FROM carts WHERE user_id = $1',
      [userId]
    );

    let cartId;
    if (cartResult.rows.length === 0) {
      const newCart = await db.query(
        'INSERT INTO carts (user_id) VALUES ($1) RETURNING id',
        [userId]
      );
      cartId = newCart.rows[0].id;
    } else {
      cartId = cartResult.rows[0].id;
    }

    // Get cart items with product details
    const items = await db.query(
      `SELECT ci.id, ci.quantity, ci.product_id,
              p.name, p.description, p.price, p.image_url, p.stock_quantity,
              (ci.quantity * p.price) as subtotal
       FROM cart_items ci
       JOIN products p ON ci.product_id = p.id
       WHERE ci.cart_id = $1`,
      [cartId]
    );

    const total = items.rows.reduce((sum, item) => sum + parseFloat(item.subtotal), 0);

    res.json({
      cartId,
      items: items.rows,
      total: total.toFixed(2),
      itemCount: items.rows.length,
    });
  } catch (error) {
    console.error('Error fetching cart:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Add item to cart
router.post('/items', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const { productId, quantity = 1 } = req.body;

    if (!productId) {
      return res.status(400).json({ error: 'Product ID is required' });
    }

    // Verify product exists and has stock
    const productCheck = await db.query(
      'SELECT id, stock_quantity FROM products WHERE id = $1',
      [productId]
    );

    if (productCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    if (productCheck.rows[0].stock_quantity < quantity) {
      return res.status(400).json({ error: 'Insufficient stock' });
    }

    // Get or create cart
    let cartResult = await db.query(
      'SELECT id FROM carts WHERE user_id = $1',
      [userId]
    );

    let cartId;
    if (cartResult.rows.length === 0) {
      const newCart = await db.query(
        'INSERT INTO carts (user_id) VALUES ($1) RETURNING id',
        [userId]
      );
      cartId = newCart.rows[0].id;
    } else {
      cartId = cartResult.rows[0].id;
    }

    // Check if item already in cart
    const existingItem = await db.query(
      'SELECT id, quantity FROM cart_items WHERE cart_id = $1 AND product_id = $2',
      [cartId, productId]
    );

    if (existingItem.rows.length > 0) {
      // Update quantity
      const newQuantity = existingItem.rows[0].quantity + quantity;
      await db.query(
        'UPDATE cart_items SET quantity = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
        [newQuantity, existingItem.rows[0].id]
      );
    } else {
      // Add new item
      await db.query(
        'INSERT INTO cart_items (cart_id, product_id, quantity) VALUES ($1, $2, $3)',
        [cartId, productId, quantity]
      );
    }

    res.status(201).json({ message: 'Item added to cart successfully' });
  } catch (error) {
    console.error('Error adding to cart:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Update cart item quantity
router.put('/items/:itemId', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const { itemId } = req.params;
    const { quantity } = req.body;

    if (!quantity || quantity < 1) {
      return res.status(400).json({ error: 'Invalid quantity' });
    }

    // Verify item belongs to user's cart
    const itemCheck = await db.query(
      `SELECT ci.id, ci.product_id, p.stock_quantity
       FROM cart_items ci
       JOIN carts c ON ci.cart_id = c.id
       JOIN products p ON ci.product_id = p.id
       WHERE ci.id = $1 AND c.user_id = $2`,
      [itemId, userId]
    );

    if (itemCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Cart item not found' });
    }

    if (itemCheck.rows[0].stock_quantity < quantity) {
      return res.status(400).json({ error: 'Insufficient stock' });
    }

    await db.query(
      'UPDATE cart_items SET quantity = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [quantity, itemId]
    );

    res.json({ message: 'Cart item updated successfully' });
  } catch (error) {
    console.error('Error updating cart item:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Remove item from cart
router.delete('/items/:itemId', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const { itemId } = req.params;

    // Verify item belongs to user's cart
    const itemCheck = await db.query(
      `SELECT ci.id
       FROM cart_items ci
       JOIN carts c ON ci.cart_id = c.id
       WHERE ci.id = $1 AND c.user_id = $2`,
      [itemId, userId]
    );

    if (itemCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Cart item not found' });
    }

    await db.query('DELETE FROM cart_items WHERE id = $1', [itemId]);

    res.json({ message: 'Item removed from cart successfully' });
  } catch (error) {
    console.error('Error removing cart item:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Clear cart
router.delete('/', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;

    const cartResult = await db.query(
      'SELECT id FROM carts WHERE user_id = $1',
      [userId]
    );

    if (cartResult.rows.length > 0) {
      await db.query('DELETE FROM cart_items WHERE cart_id = $1', [cartResult.rows[0].id]);
    }

    res.json({ message: 'Cart cleared successfully' });
  } catch (error) {
    console.error('Error clearing cart:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
