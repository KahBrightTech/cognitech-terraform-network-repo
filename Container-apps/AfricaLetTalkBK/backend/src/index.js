const express = require('express');
const cors = require('cors');
const path = require('path');
const { pool } = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve uploaded files
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

// Request logging
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/posts', require('./routes/posts'));
app.use('/api/news', require('./routes/news'));
app.use('/api/live', require('./routes/live'));
app.use('/api/messages', require('./routes/messages'));
app.use('/api/friends', require('./routes/friends'));
app.use('/api/notifications', require('./routes/notifications'));

// Reverse geocoding proxy (avoids browser CORS/mixed-content issues)
app.get('/api/geocode/reverse', async (req, res) => {
    try {
        const { lat, lon } = req.query;
        if (!lat || !lon) return res.status(400).json({ error: 'lat and lon required' });
        const response = await fetch(
            `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&zoom=10&addressdetails=1`,
            { headers: { 'Accept-Language': 'en', 'User-Agent': 'LetsConnectAfrika/1.0' } }
        );
        if (response.ok) {
            const data = await response.json();
            res.json(data);
        } else {
            res.status(502).json({ error: 'Geocoding service error' });
        }
    } catch (error) {
        console.error('Geocode error:', error);
        res.status(500).json({ error: 'Geocoding failed' });
    }
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({ 
        message: 'LetsConnectAfrika API',
        version: '1.0.0',
        endpoints: [
            '/api/health',
            '/api/auth/register',
            '/api/auth/login',
            '/api/auth/verify',
            '/api/users/:userId',
            '/api/posts',
            '/api/posts/feed'
        ]
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Route not found' });
});

// Start server
const { initializeDatabase } = require('../db-init');

initializeDatabase()
    .then(() => {
        const server = app.listen(PORT, '0.0.0.0', () => {
            console.log(`🚀 Server running on port ${PORT}`);
            console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
        });
        process.on('SIGTERM', () => {
            console.log('SIGTERM received, shutting down gracefully');
            server.close(() => {
                pool.end();
                console.log('Server closed');
                process.exit(0);
            });
        });
    })
    .catch((err) => {
        console.error('❌ Database initialization failed, server not started:', err);
        process.exit(1);
    });

module.exports = app;