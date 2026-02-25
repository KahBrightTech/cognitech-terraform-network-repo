const express = require('express');
const db = require('../config/database');

const router = express.Router();

// Get all categories
router.get('/', async (req, res) => {
  try {
    const result = await db.query(
      'SELECT * FROM categories ORDER BY country, name'
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get single category by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await db.query(
      'SELECT * FROM categories WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Category not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching category:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get categories by country
router.get('/country/:country', async (req, res) => {
  try {
    const { country } = req.params;
    
    const result = await db.query(
      'SELECT * FROM categories WHERE country = $1 ORDER BY name',
      [country]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching categories by country:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
