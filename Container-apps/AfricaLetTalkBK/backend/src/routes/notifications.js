const express = require('express');
const router = express.Router();
const { query } = require('../db');
const { authenticate } = require('../middleware/auth');

// Get notifications for current user
router.get('/', authenticate, async (req, res) => {
    try {
        const userId = req.user.userId;
        const result = await query(
            `SELECT n.*, u.username, u.full_name, u.avatar_url
             FROM notifications n
             LEFT JOIN users u ON n.from_user_id = u.id
             WHERE n.user_id = $1
             ORDER BY n.created_at DESC
             LIMIT 50`,
            [userId]
        );
        res.json({ notifications: result.rows });
    } catch (error) {
        console.error('Get notifications error:', error);
        res.status(500).json({ error: 'Failed to get notifications' });
    }
});

// Get unread notification count
router.get('/unread-count', authenticate, async (req, res) => {
    try {
        const userId = req.user.userId;
        const result = await query(
            'SELECT COUNT(*) as count FROM notifications WHERE user_id = $1 AND is_read = false',
            [userId]
        );
        res.json({ count: parseInt(result.rows[0].count) });
    } catch (error) {
        console.error('Get unread count error:', error);
        res.status(500).json({ error: 'Failed to get unread count' });
    }
});

// Mark single notification as read
router.post('/:notificationId/read', authenticate, async (req, res) => {
    try {
        await query(
            'UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2',
            [req.params.notificationId, req.user.userId]
        );
        res.json({ success: true });
    } catch (error) {
        console.error('Mark read error:', error);
        res.status(500).json({ error: 'Failed to mark as read' });
    }
});

// Mark all notifications as read
router.post('/read-all', authenticate, async (req, res) => {
    try {
        await query(
            'UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false',
            [req.user.userId]
        );
        res.json({ success: true });
    } catch (error) {
        console.error('Mark all read error:', error);
        res.status(500).json({ error: 'Failed to mark all as read' });
    }
});

module.exports = router;
