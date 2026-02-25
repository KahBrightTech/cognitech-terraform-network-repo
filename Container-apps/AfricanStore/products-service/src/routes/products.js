const express = require('express');
const db = require('../config/database');

const router = express.Router();

// Get all products with optional filters
router.get('/', async (req, res) => {
  try {
    const { category, country, minPrice, maxPrice, search } = req.query;
    
    let query = `
      SELECT p.*, c.name as category_name, c.country as category_country
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE 1=1
    `;
    const params = [];
    let paramCount = 1;

    if (category) {
      query += ` AND p.category_id = $${paramCount}`;
      params.push(category);
      paramCount++;
    }

    if (country) {
      query += ` AND p.country = $${paramCount}`;
      params.push(country);
      paramCount++;
    }

    if (minPrice) {
      query += ` AND p.price >= $${paramCount}`;
      params.push(minPrice);
      paramCount++;
    }

    if (maxPrice) {
      query += ` AND p.price <= $${paramCount}`;
      params.push(maxPrice);
      paramCount++;
    }

    if (search) {
      query += ` AND (p.name ILIKE $${paramCount} OR p.description ILIKE $${paramCount})`;
      params.push(`%${search}%`);
      paramCount++;
    }

    query += ' ORDER BY p.created_at DESC';

    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get single product by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await db.query(
      `SELECT p.*, c.name as category_name, c.country as category_country, c.description as category_description
       FROM products p
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching product:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get products by category
router.get('/category/:categoryId', async (req, res) => {
  try {
    const { categoryId } = req.params;
    
    const result = await db.query(
      `SELECT p.*, c.name as category_name
       FROM products p
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.category_id = $1
       ORDER BY p.created_at DESC`,
      [categoryId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching products by category:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get products by country
router.get('/country/:country', async (req, res) => {
  try {
    const { country } = req.params;
    
    const result = await db.query(
      `SELECT p.*, c.name as category_name
       FROM products p
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.country = $1
       ORDER BY p.created_at DESC`,
      [country]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching products by country:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get available countries
router.get('/meta/countries', async (req, res) => {
  try {
    const result = await db.query(
      'SELECT DISTINCT country FROM products ORDER BY country'
    );
    res.json(result.rows.map(row => row.country));
  } catch (error) {
    console.error('Error fetching countries:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
