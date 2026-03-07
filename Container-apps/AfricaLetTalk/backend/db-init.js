const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
  host:     process.env.DB_HOST,
  port:     process.env.DB_PORT,
  database: process.env.DB_NAME,
  user:     process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  ssl: {
    rejectUnauthorized: false  // required for RDS
  }
});

async function initializeDatabase() {
  const client = await pool.connect();
  try {
    // Check if schema already exists by looking for the users table
    const result = await client.query(`
      SELECT COUNT(*) FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'users'
    `);

    if (result.rows[0].count === '0') {
      console.log('🔧 First run detected - initializing AfricaLetTalk schema...');
      const sql = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
      await client.query(sql);
      console.log('✅ Schema initialized successfully');
      console.log('   Tables created: users, friendships, posts, comments, likes');
      console.log('   Tables created: stories, story_views, notifications');
      console.log('   Tables created: live_streams, conversations, messages');
    } else {
      console.log('✅ Schema already exists - skipping initialization');
    }

    // Fix any existing users stuck with email_verified = false
    const unverified = await client.query(
      `UPDATE users SET email_verified = true WHERE email_verified = false RETURNING id`
    );
    if (unverified.rowCount > 0) {
      console.log(`✅ Auto-verified ${unverified.rowCount} existing user(s)`);
    }
  } catch (err) {
    console.error('❌ Database initialization failed:', err);
    throw err;  // rethrow so server doesn't start with broken DB
  } finally {
    client.release();
  }
}

module.exports = { initializeDatabase, pool };
