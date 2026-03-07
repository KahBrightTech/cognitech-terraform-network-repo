const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { query } = require('../db');
const { sendVerificationEmail } = require('../utils/mailer');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

router.post('/register', async (req, res) => {
    try {
        const { username, email, password, fullName } = req.body;

        const existingUser = await query(
            'SELECT id FROM users WHERE email = $1 OR username = $2',
            [email, username]
        );

        if (existingUser.rows.length > 0) {
            return res.status(400).json({ error: 'User already exists' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const verificationToken = crypto.randomBytes(32).toString('hex');

        const result = await query(
            `INSERT INTO users (username, email, password, full_name, email_verified, verification_token, created_at) 
             VALUES ($1, $2, $3, $4, false, $5, NOW()) 
             RETURNING id, username, email, full_name, avatar_url, created_at`,
            [username, email, hashedPassword, fullName, verificationToken]
        );

        const user = result.rows[0];

        // Send verification email
        try {
            await sendVerificationEmail(email, fullName || username, verificationToken);
        } catch (emailErr) {
            console.error('Failed to send verification email:', emailErr);
        }

        res.status(201).json({ 
            message: 'Account created. Please check your email to verify your account.',
            email: email,
            requiresVerification: true
        });
    } catch (error) {
        console.error('Register error:', error);
        res.status(500).json({ error: 'Registration failed' });
    }
});

// Verify email
router.get('/verify-email', async (req, res) => {
    try {
        const { token } = req.query;

        if (!token) {
            return res.status(400).json({ error: 'Verification token is required' });
        }

        const result = await query(
            `UPDATE users SET email_verified = true, verification_token = NULL
             WHERE verification_token = $1 AND email_verified = false
             RETURNING id, username, email, full_name, avatar_url, created_at`,
            [token]
        );

        if (result.rows.length === 0) {
            return res.status(400).json({ error: 'Invalid or expired verification link' });
        }

        const user = result.rows[0];
        const jwtToken = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '7d' });

        res.json({ message: 'Email verified successfully', user, token: jwtToken });
    } catch (error) {
        console.error('Verify email error:', error);
        res.status(500).json({ error: 'Verification failed' });
    }
});

// Resend verification email
router.post('/resend-verification', async (req, res) => {
    try {
        const { email } = req.body;

        const result = await query(
            'SELECT id, username, full_name, email_verified, verification_token FROM users WHERE email = $1',
            [email]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        const user = result.rows[0];

        if (user.email_verified) {
            return res.status(400).json({ error: 'Email is already verified' });
        }

        // Generate new token if needed
        let token = user.verification_token;
        if (!token) {
            token = crypto.randomBytes(32).toString('hex');
            await query('UPDATE users SET verification_token = $1 WHERE id = $2', [token, user.id]);
        }

        await sendVerificationEmail(email, user.full_name || user.username, token);

        res.json({ message: 'Verification email sent' });
    } catch (error) {
        console.error('Resend verification error:', error);
        res.status(500).json({ error: 'Failed to resend verification email' });
    }
});

router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        const result = await query('SELECT * FROM users WHERE email = $1', [email]);

        if (result.rows.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const user = result.rows[0];
        const validPassword = await bcrypt.compare(password, user.password);
        
        if (!validPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        if (!user.email_verified) {
            return res.status(403).json({ 
                error: 'Please verify your email before logging in',
                requiresVerification: true,
                email: user.email
            });
        }

        const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '7d' });

        delete user.password;
        delete user.verification_token;

        res.json({ user, token });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Login failed' });
    }
});

router.get('/verify', async (req, res) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        
        if (!token) {
            return res.status(401).json({ error: 'No token provided' });
        }

        const decoded = jwt.verify(token, JWT_SECRET);
        const result = await query(
            'SELECT id, username, email, full_name, avatar_url, bio, created_at FROM users WHERE id = $1',
            [decoded.userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json({ user: result.rows[0] });
    } catch (error) {
        res.status(401).json({ error: 'Invalid token' });
    }
});

module.exports = router;
