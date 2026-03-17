# AfricaLetTalk - Deployment & Setup Guide

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose installed
- PostgreSQL database (local or AWS RDS)
- SMTP email account (Gmail, SendGrid, etc.)

### 1. Configure Environment Variables

```bash
# Copy the example file
cp .env.example .env

# Edit .env with your actual credentials
nano .env
```

**Required Settings:**
- Database credentials (DB_HOST, DB_NAME, DB_USERNAME, DB_PASSWORD)
- JWT_SECRET (generate a random 64+ character string)
- SMTP credentials (SMTP_USER, SMTP_PASS) - **CRITICAL for user login**
- FRONTEND_URL (your public website URL)

### 2. Build and Start Containers

```bash
# Build containers
docker-compose build --no-cache

# Start services
docker-compose up -d

# View logs
docker-compose logs -f
```

### 3. Verify Deployment

```bash
# Check backend health
curl http://localhost:3000/api/health

# Check frontend
curl http://localhost

# View running containers
docker-compose ps
```

---

## 🎨 Recent Updates

### Dark Theme Implementation
- **Login Page**: Beautiful dark UI with Cognitech branding
- **Home Page**: Clean, professional dark theme with logo and sign-in buttons only
- **Removed**: All photos, feature sections, and gallery from home page
- **Added**: Cognitech logo and "powered by cognitech" footer

### Bug Fixes
- ✅ Fixed nginx environment variable injection
- ✅ Fixed API proxy configuration
- ✅ Added comprehensive error handling

---

## 🔧 Configuration Details

### Email Verification (REQUIRED)

Users **MUST** verify their email before logging in. Configure SMTP in `.env`:

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

**For Gmail:**
1. Enable 2-factor authentication
2. Generate App Password: https://myaccount.google.com/apppasswords
3. Use the app password (not your regular password)

### Backend URL Configuration

The frontend uses nginx to proxy API requests to the backend:

```env
BACKEND_URL=http://backend:3000
```

This is automatically configured in Docker Compose but can be changed for production deployments (ECS, Kubernetes, etc.).

---

## 📝 Application Flow

1. **User Registration**
   - User fills out registration form
   - Account created with `email_verified = false`
   - Verification email sent via SMTP
   
2. **Email Verification**
   - User clicks link in email
   - Email verified, `email_verified = true`
   - User can now login

3. **Login**
   - User enters email and password
   - System checks `email_verified` status
   - If verified, user logs in
   - If not verified, error message with "Resend" option

---

## 🐛 Troubleshooting

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for detailed solutions to common issues:

- New users getting "Network Error"
- Old users getting "Invalid Credentials"
- Email verification not working
- SMTP configuration errors
- Docker networking issues

**Quick Diagnostics:**

```bash
# View all logs
docker-compose logs -f

# Check backend health
curl http://localhost:3000/api/health

# Test database connection
docker-compose exec backend node -e "require('./src/db').pool.query('SELECT NOW()', (e,r) => console.log(e || r.rows[0]))"

# Check SMTP configuration
docker-compose exec backend env | grep SMTP
```

---

## 🏗️ Architecture

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │
       │ HTTP (Port 80)
       │
┌──────▼──────────────┐
│  Frontend (Nginx)   │
│  - React App        │
│  - API Proxy        │
└──────┬──────────────┘
       │
       │ /api/* → http://backend:3000
       │
┌──────▼──────────────┐
│  Backend (Node.js)  │
│  - Express API      │
│  - Authentication   │
│  - Email Service    │
└──────┬──────────────┘
       │
       │ PostgreSQL
       │
┌──────▼──────────────┐
│    Database (RDS)   │
│  - User Data        │
│  - Posts, etc.      │
└─────────────────────┘
```

---

## 📂 Project Structure

```
AfricaLetTalk/
├── backend/
│   ├── src/
│   │   ├── routes/       # API endpoints
│   │   ├── middleware/   # Auth middleware
│   │   ├── utils/        # Email service
│   │   ├── db.js         # Database connection
│   │   └── index.js      # Express server
│   ├── Dockerfile
│   └── package.json
├── frontend/
│   ├── src/
│   │   ├── pages/        # React pages
│   │   ├── components/   # React components
│   │   ├── App.js
│   │   └── index.css     # Styles (dark theme)
│   ├── public/
│   │   └── cognitech-logo.svg  # Logo
│   ├── nginx.conf        # Nginx config
│   ├── Dockerfile
│   └── package.json
├── docker-compose.yml
├── .env.example          # Environment template
├── TROUBLESHOOTING.md    # Detailed troubleshooting
└── README.md            # This file
```

---

## 🔒 Security Notes

1. **Never commit `.env` file** - Add to `.gitignore`
2. **Change JWT_SECRET** - Use random 64+ character string
3. **Use strong database password**
4. **Enable HTTPS** in production
5. **Use app passwords** for Gmail SMTP

---

## 🚢 Deploying to Production

### AWS ECS/Fargate

1. Create RDS PostgreSQL database
2. Configure AWS Secrets Manager for credentials
3. Update `docker-compose.yml` with production values
4. Deploy containers to ECS
5. Configure Application Load Balancer
6. Point domain to ALB
7. Enable HTTPS with ACM certificate

### Environment Variables for Production

```env
DB_HOST=your-rds-endpoint.rds.amazonaws.com
FRONTEND_URL=https://yourdomain.com
BACKEND_URL=http://your-backend-service:3000
# ... other production values
```

---

## 📞 Support

For issues and questions:
1. Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Review Docker logs: `docker-compose logs -f`
3. Verify environment variables
4. Check database connectivity

---

## 📄 License

Proprietary - Cognitech © 2026
