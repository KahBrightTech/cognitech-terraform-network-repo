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

    // Ensure email_verified and verification_token columns exist (migration for older DBs)
    await client.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='email_verified') THEN
          ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT false;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='verification_token') THEN
          ALTER TABLE users ADD COLUMN verification_token VARCHAR(64);
        END IF;
      END $$;
    `);
  } catch (err) {
    console.error('❌ Database initialization failed:', err);
    throw err;  // rethrow so server doesn't start with broken DB
  } finally {
    client.release();
  }
}

module.exports = { initializeDatabase, pool };
