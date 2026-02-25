const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { query } = require('../db');
const { authenticate } = require('../middleware/auth');

// Multer storage config
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, path.join(__dirname, '..', '..', 'uploads'));
    },
    filename: (req, file, cb) => {
        const uniqueName = `${Date.now()}-${Math.round(Math.random() * 1E9)}${path.extname(file.originalname)}`;
        cb(null, uniqueName);
    }
});

const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
    fileFilter: (req, file, cb) => {
        const allowed = /jpeg|jpg|png|gif|webp/;
        const ext = allowed.test(path.extname(file.originalname).toLowerCase());
        const mime = allowed.test(file.mimetype);
        if (ext && mime) cb(null, true);
        else cb(new Error('Only image files are allowed'));
    }
});

router.post('/feed', authenticate, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { limit = 20, offset = 0 } = req.body;

        const result = await query(
            `SELECT 
                p.*,
                u.username,
                u.full_name,
                u.avatar_url,
                (SELECT COUNT(*) FROM likes WHERE post_id = p.id) as likes_count,
                (SELECT COUNT(*) FROM comments WHERE post_id = p.id) as comments_count,
                EXISTS(SELECT 1 FROM likes WHERE post_id = p.id AND user_id = $1) as is_liked
             FROM posts p
             JOIN users u ON p.user_id = u.id
             WHERE p.user_id = $1 
                OR p.user_id IN (
                    SELECT CASE 
                        WHEN user1_id = $1 THEN user2_id
                        ELSE user1_id
                    END
                    FROM friendships
                    WHERE (user1_id = $1 OR user2_id = $1) AND status = 'accepted'
                )
             ORDER BY p.created_at DESC
             LIMIT $2 OFFSET $3`,
            [userId, limit, offset]
        );

        res.json({ posts: result.rows });
    } catch (error) {
        console.error('Get feed error:', error);
        res.status(500).json({ error: 'Failed to get feed' });
    }
});

router.post('/', authenticate, upload.array('images', 4), async (req, res) => {
    try {
        const { content } = req.body;
        const userId = req.user.userId;

        if ((!content || content.trim().length === 0) && (!req.files || req.files.length === 0)) {
            return res.status(400).json({ error: 'Content or image is required' });
        }

        const mediaUrls = req.files ? req.files.map(f => `/uploads/${f.filename}`) : [];

        const result = await query(
            `INSERT INTO posts (user_id, content, media_urls, created_at) 
             VALUES ($1, $2, $3, NOW()) 
             RETURNING *`,
            [userId, content || '', mediaUrls]
        );

        // Notify all friends about the new post
        try {
            const poster = await query('SELECT username, full_name FROM users WHERE id = $1', [userId]);
            const posterName = poster.rows[0]?.full_name || poster.rows[0]?.username || 'Someone';
            const friends = await query(
                `SELECT CASE WHEN user1_id = $1 THEN user2_id ELSE user1_id END as friend_id
                 FROM friendships
                 WHERE (user1_id = $1 OR user2_id = $1) AND status = 'accepted'`,
                [userId]
            );

            // Check if the post contains a location tag
            const locationMatch = (content || '').match(/— 📍 (.+?)$/);
            const hasLocation = !!locationMatch;
            const locationName = hasLocation ? locationMatch[1].trim() : null;

            const postPreview = (content || '').substring(0, 80) + ((content || '').length > 80 ? '...' : '');
            for (const friend of friends.rows) {
                // Always send the post notification
                await query(
                    `INSERT INTO notifications (user_id, from_user_id, type, content, related_id)
                     VALUES ($1, $2, 'friend_post', $3, $4)`,
                    [friend.friend_id, userId, `${posterName} posted: "${postPreview || 'a photo'}"`, result.rows[0].id]
                );
                // If post has location, also send a location notification
                if (hasLocation) {
                    await query(
                        `INSERT INTO notifications (user_id, from_user_id, type, content, related_id)
                         VALUES ($1, $2, 'friend_location', $3, $4)`,
                        [friend.friend_id, userId, `${posterName} checked in at ${locationName} 📍`, result.rows[0].id]
                    );
                }
            }
        } catch (notifErr) {
            console.error('Post notification error (non-fatal):', notifErr);
        }

        res.status(201).json({ post: result.rows[0] });
    } catch (error) {
        console.error('Create post error:', error);
        res.status(500).json({ error: 'Failed to create post' });
    }
});

router.post('/:postId/like', authenticate, async (req, res) => {
    try {
        const { postId } = req.params;
        const userId = req.user.userId;

        const existing = await query(
            'SELECT * FROM likes WHERE post_id = $1 AND user_id = $2',
            [postId, userId]
        );

        if (existing.rows.length > 0) {
            await query('DELETE FROM likes WHERE post_id = $1 AND user_id = $2', [postId, userId]);
            res.json({ liked: false });
        } else {
            await query(
                'INSERT INTO likes (post_id, user_id, created_at) VALUES ($1, $2, NOW())',
                [postId, userId]
            );
            res.json({ liked: true });
        }
    } catch (error) {
        console.error('Like post error:', error);
        res.status(500).json({ error: 'Failed to like post' });
    }
});

// Get comments for a post
router.get('/:postId/comments', authenticate, async (req, res) => {
    try {
        const { postId } = req.params;
        const result = await query(
            `SELECT c.*, u.username, u.full_name, u.avatar_url
             FROM comments c
             JOIN users u ON c.user_id = u.id
             WHERE c.post_id = $1
             ORDER BY c.created_at ASC`,
            [postId]
        );
        res.json({ comments: result.rows });
    } catch (error) {
        console.error('Get comments error:', error);
        res.status(500).json({ error: 'Failed to get comments' });
    }
});

// Add a comment to a post
router.post('/:postId/comments', authenticate, async (req, res) => {
    try {
        const { postId } = req.params;
        const userId = req.user.userId;
        const { content } = req.body;

        if (!content || content.trim().length === 0) {
            return res.status(400).json({ error: 'Comment cannot be empty' });
        }

        const result = await query(
            `INSERT INTO comments (post_id, user_id, content, created_at)
             VALUES ($1, $2, $3, NOW())
             RETURNING *`,
            [postId, userId, content.trim()]
        );

        // Fetch with user info
        const comment = await query(
            `SELECT c.*, u.username, u.full_name, u.avatar_url
             FROM comments c
             JOIN users u ON c.user_id = u.id
             WHERE c.id = $1`,
            [result.rows[0].id]
        );

        res.status(201).json({ comment: comment.rows[0] });
    } catch (error) {
        console.error('Create comment error:', error);
        res.status(500).json({ error: 'Failed to create comment' });
    }
});

module.exports = router;
