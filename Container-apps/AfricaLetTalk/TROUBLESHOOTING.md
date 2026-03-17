# AfricaLetTalk - Troubleshooting Guide

## Issues and Solutions

### 🔴 Issue 1: New Users Getting "Network Error"

**Root Cause:** The frontend container cannot connect to the backend API.

**Solutions:**

1. **Check Environment Variables**
   ```bash
   # Verify BACKEND_URL is set in docker-compose.yml
   docker-compose config | grep BACKEND_URL
   ```
   Should output: `BACKEND_URL: http://backend:3000`

2. **Check Backend Health**
   ```bash
   # Check if backend is running
   docker-compose ps
   
   # Check backend logs
   docker-compose logs backend
   
   # Test backend directly
   curl http://localhost:3000/api/health
   ```

3. **Rebuild Containers** (after fixing nginx.conf)
   ```bash
   # Stop all containers
   docker-compose down
   
   # Rebuild with no cache
   docker-compose build --no-cache
   
   # Start containers
   docker-compose up -d
   
   # Check logs
   docker-compose logs -f
   ```

4. **Verify Network Connectivity**
   ```bash
   # Enter frontend container
   docker exec -it africaletstalk-frontend sh
   
   # Test backend connection from inside frontend
   wget -O- http://backend:3000/api/health
   ```

---

### 🔴 Issue 2: Old Users Getting "Invalid Credentials"

**Possible Causes:**

1. **Database was reset** - User accounts no longer exist
2. **Email not verified** - Users must verify email to login
3. **Password changed** - Password hashing changed

**Solutions:**

1. **Check if user exists in database**
   ```sql
   SELECT id, username, email, email_verified 
   FROM users 
   WHERE email = 'user@example.com';
   ```

2. **Check email verification status**
   - Users MUST verify their email before logging in
   - Check the `email_verified` column in database
   - If false, user needs to:
     - Check their email inbox/spam for verification email
     - Use "Resend Verification Email" button on login page

3. **Reset user password** (if needed)
   ```sql
   -- Generate new password hash
   -- Run this in Node.js: bcrypt.hashSync('newpassword', 10)
   
   UPDATE users 
   SET password = '$2a$10$...' 
   WHERE email = 'user@example.com';
   ```

4. **Manually verify email** (emergency only)
   ```sql
   UPDATE users 
   SET email_verified = true, 
       verification_token = NULL 
   WHERE email = 'user@example.com';
   ```

---

### 🔴 Issue 3: Email Verification Not Working

**Root Cause:** SMTP credentials not configured or incorrect.

**Solutions:**

1. **Configure SMTP in .env file**
   ```bash
   # Copy example file
   cp .env.example .env
   
   # Edit .env and add your SMTP credentials
   nano .env
   ```

2. **For Gmail Users:**
   - Enable 2-factor authentication
   - Generate App Password:
     1. Go to https://myaccount.google.com/apppasswords
     2. Select "Mail" and your device
     3. Copy the 16-character password
     4. Use this in SMTP_PASS

3. **Test SMTP Connection**
   ```bash
   # Check backend logs for SMTP errors
   docker-compose logs backend | grep -i smtp
   docker-compose logs backend | grep -i email
   ```

4. **Verify Environment Variables**
   ```bash
   # Check if SMTP vars are loaded
   docker exec africaletstalk-backend env | grep SMTP
   ```

5. **Restart after configuring**
   ```bash
   docker-compose restart backend
   ```

---

## Quick Diagnostic Commands

```bash
# Check all containers status
docker-compose ps

# View all logs
docker-compose logs

# View backend logs only
docker-compose logs -f backend

# View frontend logs only
docker-compose logs -f frontend

# Check backend health endpoint
curl http://localhost:3000/api/health

# Test login endpoint
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Check database connection
docker-compose exec backend node -e "
  const { pool } = require('./src/db');
  pool.query('SELECT NOW()', (err, res) => {
    console.log(err ? 'DB Connection Failed' : 'DB Connected: ' + res.rows[0].now);
    process.exit();
  });
"
```

---

## Environment Variable Checklist

Before starting the application, ensure these are configured:

- [ ] `DB_HOST` - Database hostname
- [ ] `DB_PORT` - Database port (default: 5432)
- [ ] `DB_NAME` - Database name
- [ ] `DB_USERNAME` - Database user
- [ ] `DB_PASSWORD` - Database password
- [ ] `JWT_SECRET` - Random secret key (64+ characters)
- [ ] `SMTP_HOST` - SMTP server (e.g., smtp.gmail.com)
- [ ] `SMTP_PORT` - SMTP port (usually 587)
- [ ] `SMTP_USER` - Email address
- [ ] `SMTP_PASS` - Email password or app password
- [ ] `FRONTEND_URL` - Public URL (e.g., http://localhost)
- [ ] `BACKEND_URL` - Backend URL for nginx (e.g., http://backend:3000)

---

## Common Fixes

### "Cannot read properties of undefined"
**Fix:** Rebuild containers after code changes
```bash
docker-compose build --no-cache
docker-compose up -d
```

### "ECONNREFUSED" or "connection refused"
**Fix:** Check if backend is running and accessible
```bash
docker-compose logs backend
docker-compose restart backend
```

### "Email sending failed"
**Fix:** Verify SMTP credentials and restart
```bash
# Update .env file with correct SMTP settings
docker-compose restart backend
```

### "Database connection error"
**Fix:** Check database credentials and network
```bash
# Test database connection
docker-compose exec backend node -e "require('./src/db').pool.query('SELECT 1')"
```

---

## Fresh Start (Nuclear Option)

If nothing works, start fresh:

```bash
# Stop and remove all containers
docker-compose down -v

# Remove all images
docker-compose down --rmi all

# Clear Docker cache
docker system prune -a --volumes

# Rebuild from scratch
docker-compose build --no-cache

# Start fresh
docker-compose up -d

# Watch logs
docker-compose logs -f
```

---

## Need More Help?

1. Check Docker logs: `docker-compose logs -f`
2. Check backend health: `curl http://localhost:3000/api/health`
3. Verify database connection
4. Ensure all environment variables are set
5. Check firewall/network settings

## Recent Changes (Fixed Issues)

✅ **FIXED:** Nginx environment variable injection
   - Changed `$BACKEND_URL` to `${BACKEND_URL}` in nginx.conf
   - Now properly substitutes environment variables

✅ **FIXED:** Home page now dark themed
   - Removed all photos and feature sections
   - Clean, professional dark theme with Cognitech branding
   - Just logo and sign-in options

✅ **ADDED:** Comprehensive environment variable documentation
   - .env.example file with all required settings
   - Detailed comments for SMTP configuration

✅ **IMPROVED:** Login page
   - Beautiful dark theme design
   - Cognitech logo and branding
   - Enhanced user experience
