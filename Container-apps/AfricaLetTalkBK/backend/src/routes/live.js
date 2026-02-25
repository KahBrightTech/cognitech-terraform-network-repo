const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { query } = require('../db');
const { authenticate } = require('../middleware/auth');

// Frame capture storage for live video
const framesDir = path.join(__dirname, '../../uploads/frames');
fs.mkdirSync(framesDir, { recursive: true });

const frameStorage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, framesDir),
    filename: (req, file, cb) => cb(null, `stream-${req.params.streamId}.jpg`)
});
const frameUpload = multer({ storage: frameStorage, limits: { fileSize: 500000 } });

// Start a live stream
router.post('/start', authenticate, async (req, res) => {
    try {
        const { title } = req.body;

        // End any existing active streams for this user
        await query(
            'UPDATE live_streams SET is_active = false, ended_at = NOW() WHERE user_id = $1 AND is_active = true',
            [req.user.userId]
        );

        const result = await query(
            'INSERT INTO live_streams (user_id, title) VALUES ($1, $2) RETURNING *',
            [req.user.userId, title || 'Live Stream']
        );

        res.status(201).json({ stream: result.rows[0] });
    } catch (error) {
        console.error('Start live error:', error);
        res.status(500).json({ error: 'Failed to start live stream' });
    }
});

// Stop a live stream
router.post('/stop', authenticate, async (req, res) => {
    try {
        const result = await query(
            'UPDATE live_streams SET is_active = false, ended_at = NOW() WHERE user_id = $1 AND is_active = true RETURNING *',
            [req.user.userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'No active stream found' });
        }

        // Clean up the frame file for this stream
        const frameFile = path.join(framesDir, `stream-${result.rows[0].id}.jpg`);
        try { fs.unlinkSync(frameFile); } catch (e) { /* ignore */ }

        res.json({ stream: result.rows[0] });
    } catch (error) {
        console.error('Stop live error:', error);
        res.status(500).json({ error: 'Failed to stop live stream' });
    }
});

// Upload a video frame from the streamer
router.post('/:streamId/frame', authenticate, frameUpload.single('frame'), async (req, res) => {
    try {
        // Verify the user owns this active stream
        const stream = await query(
            'SELECT id FROM live_streams WHERE id = $1 AND user_id = $2 AND is_active = true',
            [req.params.streamId, req.user.userId]
        );
        if (stream.rows.length === 0) {
            return res.status(403).json({ error: 'Not your stream or stream ended' });
        }
        res.json({ success: true });
    } catch (error) {
        console.error('Frame upload error:', error);
        res.status(500).json({ error: 'Failed to upload frame' });
    }
});

// Get all active live streams
router.get('/active', authenticate, async (req, res) => {
    try {
        const result = await query(
            `SELECT ls.*, u.username, u.full_name, u.avatar_url
             FROM live_streams ls
             JOIN users u ON ls.user_id = u.id
             WHERE ls.is_active = true
             ORDER BY ls.started_at DESC`
        );

        res.json({ streams: result.rows });
    } catch (error) {
        console.error('Get active streams error:', error);
        res.status(500).json({ error: 'Failed to get live streams' });
    }
});

// Join/view a live stream (increment viewer count)
router.post('/:streamId/join', authenticate, async (req, res) => {
    try {
        const result = await query(
            'UPDATE live_streams SET viewer_count = viewer_count + 1 WHERE id = $1 AND is_active = true RETURNING *',
            [req.params.streamId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Stream not found or ended' });
        }

        // Get user info for the stream
        const streamWithUser = await query(
            `SELECT ls.*, u.username, u.full_name, u.avatar_url
             FROM live_streams ls
             JOIN users u ON ls.user_id = u.id
             WHERE ls.id = $1`,
            [req.params.streamId]
        );

        res.json({ stream: streamWithUser.rows[0] });
    } catch (error) {
        console.error('Join stream error:', error);
        res.status(500).json({ error: 'Failed to join stream' });
    }
});

// Leave a live stream (decrement viewer count)
router.post('/:streamId/leave', authenticate, async (req, res) => {
    try {
        await query(
            'UPDATE live_streams SET viewer_count = GREATEST(viewer_count - 1, 0) WHERE id = $1',
            [req.params.streamId]
        );
        res.json({ success: true });
    } catch (error) {
        console.error('Leave stream error:', error);
        res.status(500).json({ error: 'Failed to leave stream' });
    }
});

// Get stream info (for polling viewer count)
router.get('/:streamId/info', authenticate, async (req, res) => {
    try {
        const result = await query(
            `SELECT ls.*, u.username, u.full_name, u.avatar_url
             FROM live_streams ls
             JOIN users u ON ls.user_id = u.id
             WHERE ls.id = $1`,
            [req.params.streamId]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Stream not found' });
        }
        res.json({ stream: result.rows[0] });
    } catch (error) {
        console.error('Get stream info error:', error);
        res.status(500).json({ error: 'Failed to get stream info' });
    }
});

// Send a chat message in a live stream
router.post('/:streamId/chat', authenticate, async (req, res) => {
    try {
        const { message } = req.body;
        if (!message || !message.trim()) {
            return res.status(400).json({ error: 'Message is required' });
        }

        // Verify stream is active
        const stream = await query('SELECT id FROM live_streams WHERE id = $1 AND is_active = true', [req.params.streamId]);
        if (stream.rows.length === 0) {
            return res.status(404).json({ error: 'Stream not found or ended' });
        }

        const result = await query(
            `INSERT INTO live_chats (stream_id, user_id, message) VALUES ($1, $2, $3) RETURNING *`,
            [req.params.streamId, req.user.userId, message.trim()]
        );

        // Return with user info
        const chat = await query(
            `SELECT lc.*, u.username, u.full_name FROM live_chats lc JOIN users u ON lc.user_id = u.id WHERE lc.id = $1`,
            [result.rows[0].id]
        );

        res.status(201).json({ chat: chat.rows[0] });
    } catch (error) {
        console.error('Live chat error:', error);
        res.status(500).json({ error: 'Failed to send message' });
    }
});

// Get chat messages for a live stream
router.get('/:streamId/chat', authenticate, async (req, res) => {
    try {
        const sinceId = parseInt(req.query.since_id) || 0;
        const result = await query(
            `SELECT lc.*, u.username, u.full_name
             FROM live_chats lc
             JOIN users u ON lc.user_id = u.id
             WHERE lc.stream_id = $1 AND lc.id > $2
             ORDER BY lc.id ASC
             LIMIT 100`,
            [req.params.streamId, sinceId]
        );

        res.json({ chats: result.rows });
    } catch (error) {
        console.error('Get live chat error:', error);
        res.status(500).json({ error: 'Failed to get chat messages' });
    }
});

module.exports = router;
