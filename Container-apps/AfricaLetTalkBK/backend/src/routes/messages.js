const express = require('express');
const router = express.Router();
const { query } = require('../db');
const { authenticate } = require('../middleware/auth');

// Get all conversations for the current user
router.get('/conversations', authenticate, async (req, res) => {
    try {
        const userId = req.user.userId;
        const result = await query(
            `SELECT 
                c.*,
                CASE WHEN c.user1_id = $1 THEN c.user2_id ELSE c.user1_id END as other_user_id,
                u.username as other_username,
                u.full_name as other_full_name,
                u.avatar_url as other_avatar_url,
                (SELECT content FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) as last_message,
                (SELECT sender_id FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) as last_sender_id,
                (SELECT COUNT(*) FROM messages WHERE conversation_id = c.id AND sender_id != $1 AND is_read = false) as unread_count
             FROM conversations c
             JOIN users u ON u.id = CASE WHEN c.user1_id = $1 THEN c.user2_id ELSE c.user1_id END
             WHERE c.user1_id = $1 OR c.user2_id = $1
             ORDER BY c.last_message_at DESC`,
            [userId]
        );
        res.json({ conversations: result.rows });
    } catch (error) {
        console.error('Get conversations error:', error);
        res.status(500).json({ error: 'Failed to get conversations' });
    }
});

// Get or create a conversation with a user
router.post('/conversations', authenticate, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { otherUserId } = req.body;

        if (!otherUserId || otherUserId === userId) {
            return res.status(400).json({ error: 'Invalid user' });
        }

        // Ensure consistent ordering: lower id = user1
        const user1 = Math.min(userId, otherUserId);
        const user2 = Math.max(userId, otherUserId);

        // Try to find existing conversation
        let result = await query(
            `SELECT * FROM conversations WHERE user1_id = $1 AND user2_id = $2`,
            [user1, user2]
        );

        if (result.rows.length === 0) {
            result = await query(
                `INSERT INTO conversations (user1_id, user2_id) VALUES ($1, $2) RETURNING *`,
                [user1, user2]
            );
        }

        const conv = result.rows[0];

        // Get other user info
        const userResult = await query(
            `SELECT id, username, full_name, avatar_url FROM users WHERE id = $1`,
            [otherUserId]
        );

        res.json({
            conversation: {
                ...conv,
                other_user_id: otherUserId,
                other_username: userResult.rows[0]?.username,
                other_full_name: userResult.rows[0]?.full_name,
                other_avatar_url: userResult.rows[0]?.avatar_url
            }
        });
    } catch (error) {
        console.error('Create conversation error:', error);
        res.status(500).json({ error: 'Failed to create conversation' });
    }
});

// Get messages for a conversation
router.get('/conversations/:convId/messages', authenticate, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { convId } = req.params;
        const { before } = req.query;

        // Verify user is part of this conversation
        const convCheck = await query(
            `SELECT * FROM conversations WHERE id = $1 AND (user1_id = $2 OR user2_id = $2)`,
            [convId, userId]
        );
        if (convCheck.rows.length === 0) {
            return res.status(403).json({ error: 'Not authorized' });
        }

        let messagesQuery;
        let params;
        if (before) {
            messagesQuery = `SELECT m.*, u.username, u.full_name, u.avatar_url
                FROM messages m JOIN users u ON m.sender_id = u.id
                WHERE m.conversation_id = $1 AND m.id < $2
                ORDER BY m.created_at DESC LIMIT 50`;
            params = [convId, before];
        } else {
            messagesQuery = `SELECT m.*, u.username, u.full_name, u.avatar_url
                FROM messages m JOIN users u ON m.sender_id = u.id
                WHERE m.conversation_id = $1
                ORDER BY m.created_at DESC LIMIT 50`;
            params = [convId];
        }

        const result = await query(messagesQuery, params);

        // Mark messages as read
        await query(
            `UPDATE messages SET is_read = true 
             WHERE conversation_id = $1 AND sender_id != $2 AND is_read = false`,
            [convId, userId]
        );

        res.json({ messages: result.rows.reverse() });
    } catch (error) {
        console.error('Get messages error:', error);
        res.status(500).json({ error: 'Failed to get messages' });
    }
});

// Send a message
router.post('/conversations/:convId/messages', authenticate, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { convId } = req.params;
        const { content } = req.body;

        if (!content || !content.trim()) {
            return res.status(400).json({ error: 'Message cannot be empty' });
        }

        // Verify user is part of this conversation
        const convCheck = await query(
            `SELECT * FROM conversations WHERE id = $1 AND (user1_id = $2 OR user2_id = $2)`,
            [convId, userId]
        );
        if (convCheck.rows.length === 0) {
            return res.status(403).json({ error: 'Not authorized' });
        }

        const result = await query(
            `INSERT INTO messages (conversation_id, sender_id, content) VALUES ($1, $2, $3) RETURNING *`,
            [convId, userId, content.trim()]
        );

        // Update conversation last_message_at
        await query(
            `UPDATE conversations SET last_message_at = NOW() WHERE id = $1`,
            [convId]
        );

        // Get message with user info
        const msg = await query(
            `SELECT m.*, u.username, u.full_name, u.avatar_url
             FROM messages m JOIN users u ON m.sender_id = u.id
             WHERE m.id = $1`,
            [result.rows[0].id]
        );

        res.status(201).json({ message: msg.rows[0] });
    } catch (error) {
        console.error('Send message error:', error);
        res.status(500).json({ error: 'Failed to send message' });
    }
});

// Get total unread message count
router.get('/unread', authenticate, async (req, res) => {
    try {
        const userId = req.user.userId;
        const result = await query(
            `SELECT COUNT(*) as count FROM messages m
             JOIN conversations c ON m.conversation_id = c.id
             WHERE (c.user1_id = $1 OR c.user2_id = $1)
             AND m.sender_id != $1 AND m.is_read = false`,
            [userId]
        );
        res.json({ unread: parseInt(result.rows[0].count) || 0 });
    } catch (error) {
        console.error('Unread count error:', error);
        res.status(500).json({ error: 'Failed to get unread count' });
    }
});

// Search users to start a conversation with
router.get('/search-users', authenticate, async (req, res) => {
    try {
        const { q } = req.query;
        const userId = req.user.userId;

        if (!q || q.length < 2) {
            return res.status(400).json({ error: 'Query too short' });
        }

        const result = await query(
            `SELECT id, username, full_name, avatar_url 
             FROM users 
             WHERE (username ILIKE $1 OR full_name ILIKE $1) AND id != $2
             LIMIT 20`,
            [`%${q}%`, userId]
        );

        res.json({ users: result.rows });
    } catch (error) {
        console.error('Search users error:', error);
        res.status(500).json({ error: 'Search failed' });
    }
});

module.exports = router;
