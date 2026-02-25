const express = require('express');
const router = express.Router();
const { query } = require('../db');
const { authenticate } = require('../middleware/auth');

// Get suggested users (real users not already friends or pending)
router.get('/suggestions', authenticate, async (req, res) => {
    try {
        const userId = req.user.userId;
        const result = await query(
            `SELECT id, username, full_name, avatar_url, bio
             FROM users
             WHERE id != $1
               AND id NOT IN (
                   SELECT CASE WHEN user1_id = $1 THEN user2_id ELSE user1_id END
                   FROM friendships
                   WHERE user1_id = $1 OR user2_id = $1
               )
             ORDER BY created_at DESC
             LIMIT 10`,
            [userId]
        );
        res.json({ users: result.rows });
    } catch (error) {
        console.error('Get suggestions error:', error);
        res.status(500).json({ error: 'Failed to get suggestions' });
    }
});

// Send friend request
router.post('/request', authenticate, async (req, res) => {
    try {
        const { toUserId } = req.body;
        const fromUserId = req.user.userId;

        if (fromUserId === parseInt(toUserId)) {
            return res.status(400).json({ error: 'Cannot send friend request to yourself' });
        }

        // Check if friendship already exists in either direction
        const existing = await query(
            `SELECT * FROM friendships 
             WHERE (user1_id = $1 AND user2_id = $2) OR (user1_id = $2 AND user2_id = $1)`,
            [fromUserId, toUserId]
        );

        if (existing.rows.length > 0) {
            return res.status(400).json({ error: 'Friend request already exists', friendship: existing.rows[0] });
        }

        const result = await query(
            `INSERT INTO friendships (user1_id, user2_id, status) VALUES ($1, $2, 'pending') RETURNING *`,
            [fromUserId, toUserId]
        );

        // Create a notification for the recipient
        const sender = await query('SELECT username, full_name FROM users WHERE id = $1', [fromUserId]);
        const senderName = sender.rows[0]?.full_name || sender.rows[0]?.username || 'Someone';
        await query(
            `INSERT INTO notifications (user_id, from_user_id, type, content, related_id)
             VALUES ($1, $2, 'friend_request', $3, $4)`,
            [toUserId, fromUserId, `${senderName} sent you a friend request`, result.rows[0].id]
        );

        res.status(201).json({ friendship: result.rows[0] });
    } catch (error) {
        console.error('Send friend request error:', error);
        res.status(500).json({ error: 'Failed to send friend request' });
    }
});

// Accept friend request
router.post('/accept', authenticate, async (req, res) => {
    try {
        const { friendshipId } = req.body;
        const userId = req.user.userId;

        // Only the recipient (user2_id) can accept
        const result = await query(
            `UPDATE friendships SET status = 'accepted'
             WHERE id = $1 AND user2_id = $2 AND status = 'pending'
             RETURNING *`,
            [friendshipId, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Friend request not found' });
        }

        // Notify the sender that their request was accepted
        const accepter = await query('SELECT username, full_name FROM users WHERE id = $1', [userId]);
        const accepterName = accepter.rows[0]?.full_name || accepter.rows[0]?.username || 'Someone';
        await query(
            `INSERT INTO notifications (user_id, from_user_id, type, content, related_id)
             VALUES ($1, $2, 'friend_accepted', $3, $4)`,
            [result.rows[0].user1_id, userId, `${accepterName} accepted your friend request`, result.rows[0].id]
        );

        res.json({ friendship: result.rows[0] });
    } catch (error) {
        console.error('Accept friend error:', error);
        res.status(500).json({ error: 'Failed to accept friend request' });
    }
});

// Reject/delete friend request or unfriend
router.post('/remove', authenticate, async (req, res) => {
    try {
        const { friendshipId } = req.body;
        const userId = req.user.userId;

        const result = await query(
            `DELETE FROM friendships 
             WHERE id = $1 AND (user1_id = $2 OR user2_id = $2)
             RETURNING *`,
            [friendshipId, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Friendship not found' });
        }

        res.json({ success: true });
    } catch (error) {
        console.error('Remove friend error:', error);
        res.status(500).json({ error: 'Failed to remove friend' });
    }
});

// Get my friends list
router.get('/list', authenticate, async (req, res) => {
    try {
        const userId = req.user.userId;
        const result = await query(
            `SELECT u.id, u.username, u.full_name, u.avatar_url, f.id as friendship_id, f.status, f.created_at as friends_since
             FROM friendships f
             JOIN users u ON (u.id = CASE WHEN f.user1_id = $1 THEN f.user2_id ELSE f.user1_id END)
             WHERE (f.user1_id = $1 OR f.user2_id = $1) AND f.status = 'accepted'
             ORDER BY f.created_at DESC`,
            [userId]
        );
        res.json({ friends: result.rows });
    } catch (error) {
        console.error('Get friends error:', error);
        res.status(500).json({ error: 'Failed to get friends' });
    }
});

// Get pending friend requests (received)
router.get('/requests', authenticate, async (req, res) => {
    try {
        const userId = req.user.userId;
        const result = await query(
            `SELECT f.id as friendship_id, f.status, f.created_at,
                    u.id as user_id, u.username, u.full_name, u.avatar_url
             FROM friendships f
             JOIN users u ON u.id = f.user1_id
             WHERE f.user2_id = $1 AND f.status = 'pending'
             ORDER BY f.created_at DESC`,
            [userId]
        );
        res.json({ requests: result.rows });
    } catch (error) {
        console.error('Get friend requests error:', error);
        res.status(500).json({ error: 'Failed to get friend requests' });
    }
});

// Get friendship status with a specific user
router.get('/status/:otherUserId', authenticate, async (req, res) => {
    try {
        const userId = req.user.userId;
        const otherId = parseInt(req.params.otherUserId);

        const result = await query(
            `SELECT * FROM friendships
             WHERE (user1_id = $1 AND user2_id = $2) OR (user1_id = $2 AND user2_id = $1)`,
            [userId, otherId]
        );

        if (result.rows.length === 0) {
            return res.json({ status: 'none' });
        }

        const f = result.rows[0];
        let status = f.status;
        if (status === 'pending') {
            // Distinguish between sent and received
            status = f.user1_id === userId ? 'sent' : 'received';
        }
        res.json({ status, friendship: f });
    } catch (error) {
        console.error('Get friendship status error:', error);
        res.status(500).json({ error: 'Failed to get friendship status' });
    }
});

module.exports = router;
