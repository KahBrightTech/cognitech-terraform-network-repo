const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { query } = require('../db');
const { authenticate } = require('../middleware/auth');

// Multer config for avatar uploads
const avatarStorage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, path.join(__dirname, '..', '..', 'uploads'));
    },
    filename: (req, file, cb) => {
        const uniqueName = `avatar-${req.user.userId}-${Date.now()}${path.extname(file.originalname)}`;
        cb(null, uniqueName);
    }
});

const avatarUpload = multer({
    storage: avatarStorage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
    fileFilter: (req, file, cb) => {
        // Accept if mime type starts with image/
        if (file.mimetype && file.mimetype.startsWith('image/')) {
            return cb(null, true);
        }
        // Fallback: check extension
        const allowedExt = /\.(jpeg|jpg|png|gif|webp|bmp|heic|heif|svg|tiff|avif)$/i;
        if (allowedExt.test(file.originalname)) {
            return cb(null, true);
        }
        cb(new Error('Only image files are allowed'));
    }
});

router.get('/:userId', authenticate, async (req, res) => {
    try {
        const { userId } = req.params;
        
        const result = await query(
            `SELECT id, username, email, full_name, avatar_url, bio, created_at 
             FROM users WHERE id = $1`,
            [userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json({ user: result.rows[0] });
    } catch (error) {
        console.error('Get user error:', error);
        res.status(500).json({ error: 'Failed to get user' });
    }
});

router.put('/:userId', authenticate, async (req, res) => {
    try {
        const { userId } = req.params;
        
        if (req.user.userId !== parseInt(userId)) {
            return res.status(403).json({ error: 'Unauthorized' });
        }

        const { fullName, bio, avatarUrl } = req.body;

        // If avatarUrl key is present in body (even if null), use the value directly
        // If not present, keep the existing avatar_url via COALESCE
        const avatarExplicit = 'avatarUrl' in req.body;
        const result = await query(
            `UPDATE users 
             SET full_name = COALESCE($1, full_name),
                 bio = COALESCE($2, bio),
                 avatar_url = CASE WHEN $5::boolean THEN $3 ELSE avatar_url END
             WHERE id = $4
             RETURNING id, username, email, full_name, avatar_url, bio, created_at`,
            [fullName, bio, avatarUrl || null, userId, avatarExplicit]
        );

        res.json({ user: result.rows[0] });
    } catch (error) {
        console.error('Update user error:', error);
        res.status(500).json({ error: 'Failed to update user' });
    }
});

router.get('/', authenticate, async (req, res) => {
    try {
        const { q } = req.query;
        
        if (!q || q.length < 2) {
            return res.status(400).json({ error: 'Search query must be at least 2 characters' });
        }

        const result = await query(
            `SELECT id, username, full_name, avatar_url 
             FROM users 
             WHERE username ILIKE $1 OR full_name ILIKE $1
             LIMIT 20`,
            [`%${q}%`]
        );

        res.json({ users: result.rows });
    } catch (error) {
        console.error('Search users error:', error);
        res.status(500).json({ error: 'Search failed' });
    }
});

// Upload avatar (with multer error handling)
router.post('/avatar', authenticate, (req, res, next) => {
    avatarUpload.single('avatar')(req, res, (err) => {
        if (err) {
            console.error('Multer avatar error:', err.message);
            if (err.code === 'LIMIT_FILE_SIZE') {
                return res.status(400).json({ error: 'File too large. Maximum 5MB.' });
            }
            return res.status(400).json({ error: err.message || 'Upload failed' });
        }
        next();
    });
}, async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        const avatarUrl = `/uploads/${req.file.filename}`;

        const result = await query(
            `UPDATE users SET avatar_url = $1 WHERE id = $2
             RETURNING id, username, email, full_name, avatar_url, bio, created_at`,
            [avatarUrl, req.user.userId]
        );

        res.json({ user: result.rows[0] });
    } catch (error) {
        console.error('Avatar upload error:', error);
        res.status(500).json({ error: 'Failed to upload avatar' });
    }
});

module.exports = router;
