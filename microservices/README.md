# 🏗️ Flutter Finance Microservices

> **Architecture:** Microservices with API Gateway Pattern  
> **Stack:** Dart (Backend) + Nginx (Gateway) + Docker + Cloudflare Tunnel  
> **Production:** https://api-flutter.vault.io.vn

---

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Services](#services)
- [Quick Start](#quick-start)
- [Production Deployment](#production-deployment)
- [Development](#development)
- [API Documentation](#api-documentation)
- [Monitoring](#monitoring)

---

## 🏛️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Cloudflare Tunnel                     │
│                  (SSL/TLS Termination)                   │
└────────────────────┬────────────────────────────────────┘
                     │ HTTPS
                     ▼
         api-flutter.vault.io.vn:8765
                     │
┌────────────────────▼────────────────────────────────────┐
│              Nginx API Gateway                           │
│  - Rate Limiting (100 req/s API, 30 req/s Chat)        │
│  - CORS Management                                       │
│  - Request Routing                                       │
│  - Security Headers                                      │
└─────────────┬───────────────────────┬───────────────────┘
              │                       │
              ▼                       ▼
    ┌─────────────────┐    ┌──────────────────┐
    │  Transaction    │    │   Chatbot AI     │
    │   Service       │    │    Service       │
    │  (Port 8080)    │    │  (Port 3002)     │
    │                 │    │                  │
    │  - CRUD Ops     │    │  - N8N Proxy     │
    │  - Supabase     │    │  - AI Chat       │
    └─────────────────┘    └──────────────────┘
              │                       │
              ▼                       ▼
    ┌─────────────────────────────────────────┐
    │         Supabase PostgreSQL              │
    │      (Cloud Database + Auth)             │
    └─────────────────────────────────────────┘
```

---

## 🔧 Services

### 1. API Gateway (Nginx)
- **Port:** 8765 (production), 3000 (development)
- **Purpose:** Single entry point, routing, security
- **Features:**
  - Rate limiting
  - CORS management
  - Request logging
  - Health checks

### 2. Transaction Service
- **Port:** 8080 (internal only)
- **Purpose:** Manage financial transactions
- **Endpoints:**
  - `GET /transactions` - List all transactions
  - `POST /transactions` - Create transaction
  - `PUT /transactions/:id` - Update transaction
  - `DELETE /transactions/:id` - Delete transaction
  - `GET /health` - Health check

### 3. Chatbot Service
- **Port:** 3002 (internal only)
- **Purpose:** AI chatbot proxy to N8N
- **Endpoints:**
  - `POST /chat/send` - Send message to AI
  - `GET /health` - Health check

---

## 🚀 Quick Start

### Development (Local)

```bash
# Start all services
cd microservices
docker-compose up -d

# View logs
docker-compose logs -f

# Test
curl http://localhost:3000/health
```

### Production (Server)

```bash
# Deploy to production
cd microservices
./deploy.sh

# Or manually
docker-compose -f docker-compose.prod.yml up -d --build

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

---

## 🌐 Production Deployment

### Prerequisites
- Docker & Docker Compose installed
- Cloudflare Tunnel configured
- Domain: `api-flutter.vault.io.vn`

### Step-by-Step Guide

1. **Configure Environment**
   ```bash
   cp .env.production.example .env.production
   nano .env.production  # Fill in credentials
   ```

2. **Deploy Services**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

3. **Configure Cloudflare Tunnel**
   - Go to Cloudflare Dashboard → Tunnels
   - Add hostname: `api-flutter.vault.io.vn` → `localhost:8765`

4. **Verify Deployment**
   ```bash
   curl https://api-flutter.vault.io.vn/health
   ```

📖 **Full Guide:** See [DEPLOYMENT.md](./DEPLOYMENT.md)  
☁️ **Cloudflare Setup:** See [CLOUDFLARE_SETUP.md](./CLOUDFLARE_SETUP.md)  
⚡ **Quick Commands:** See [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)

---

## 💻 Development

### Run Individual Services

**Transaction Service:**
```bash
cd transaction_service
dart pub get
dart run bin/server.dart
# → http://localhost:8080
```

**Chatbot Service:**
```bash
cd chatbot_service
dart pub get
dart run bin/server.dart
# → http://localhost:3002
```

### Project Structure

```
microservices/
├── api_gateway/
│   ├── nginx.conf              # Development config
│   └── nginx.prod.conf         # Production config
├── transaction_service/
│   ├── bin/server.dart         # Entry point
│   ├── lib/handlers/           # HTTP handlers
│   ├── lib/data/               # Data layer
│   └── Dockerfile
├── chatbot_service/
│   ├── bin/server.dart         # Entry point
│   └── Dockerfile
├── docker-compose.yml          # Development
├── docker-compose.prod.yml     # Production
├── .env.production             # Production secrets (not in git)
├── deploy.sh                   # Deployment script (Linux/Mac)
└── deploy.ps1                  # Deployment script (Windows)
```

---

## 📚 API Documentation

### Base URLs
- **Production:** `https://api-flutter.vault.io.vn`
- **Development:** `http://localhost:3000`

### Endpoints

#### Health Check
```http
GET /health
```
Response:
```json
{
  "status": "healthy",
  "service": "api_gateway",
  "timestamp": "2026-05-06T04:44:10Z",
  "version": "1.0.0"
}
```

#### List Transactions
```http
GET /transactions
Authorization: Bearer {supabase_token}
```

#### Create Transaction
```http
POST /transactions
Content-Type: application/json
Authorization: Bearer {supabase_token}

{
  "amount": 50000,
  "is_expense": true,
  "category_name": "Food",
  "note": "Lunch"
}
```

#### AI Chatbot
```http
POST /chat
Content-Type: application/json

{
  "message": "Hôm nay tôi chi 50k ăn phở",
  "userId": "user-id"
}
```

### Rate Limits
- **API Endpoints:** 100 requests/second
- **Chat Endpoint:** 30 requests/second

---

## 📊 Monitoring

### Check Service Status
```bash
docker-compose -f docker-compose.prod.yml ps
```

### View Logs
```bash
# All services
docker-compose -f docker-compose.prod.yml logs -f

# Specific service
docker logs -f flutter_api_gateway_prod
docker logs -f flutter_transaction_service_prod
docker logs -f flutter_chatbot_service_prod
```

### Health Checks
```bash
# Gateway
curl https://api-flutter.vault.io.vn/health

# Transaction Service (internal)
docker exec flutter_transaction_service_prod wget -qO- http://localhost:8080/health

# Chatbot Service (internal)
docker exec flutter_chatbot_service_prod wget -qO- http://localhost:3002/health
```

### Resource Usage
```bash
docker stats
```

---

## 🔒 Security

✅ **Implemented:**
- Internal services not exposed to internet
- Rate limiting on all endpoints
- CORS restricted to authorized domains
- Security headers (X-Frame-Options, CSP, etc.)
- SSL/TLS via Cloudflare
- Automatic service restart on failure
- Log rotation to prevent disk fill

---

## 🛠️ Maintenance

### Update Deployment
```bash
git pull origin main
./deploy.sh
```

### Restart Services
```bash
docker-compose -f docker-compose.prod.yml restart
```

### Stop Services
```bash
docker-compose -f docker-compose.prod.yml down
```

### Clean Up
```bash
docker-compose -f docker-compose.prod.yml down -v --rmi all
```

---

## 🐛 Troubleshooting

### Services won't start
```bash
docker-compose -f docker-compose.prod.yml logs
```

### Port already in use
```bash
netstat -tulpn | grep 8765
# Change port in docker-compose.prod.yml if needed
```

### Can't connect from Flutter app
1. Check Cloudflare Tunnel status
2. Verify DNS: `nslookup api-flutter.vault.io.vn`
3. Test endpoint: `curl https://api-flutter.vault.io.vn/health`

📖 **More Solutions:** See [DEPLOYMENT.md](./DEPLOYMENT.md) → Troubleshooting

---

## 📝 Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SUPABASE_URL` | Supabase project URL | `https://xxx.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase anonymous key | `eyJhbGc...` |
| `ARCHITECTURE_MODE` | Architecture mode | `microservices` |
| `MICROSERVICE_URL` | API base URL | `https://api-flutter.vault.io.vn` |
| `N8N_WEBHOOK_URL` | N8N webhook endpoint | `https://n8n.vault.io.vn/webhook/ai-chat` |

---

## 🎯 Production URLs

| Service | URL |
|---------|-----|
| API Gateway | https://api-flutter.vault.io.vn |
| Flutter App | https://flutter.vault.io.vn |
| N8N Webhook | https://n8n.vault.io.vn/webhook/ai-chat |

---

## 📖 Additional Documentation

- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Complete deployment guide
- **[CLOUDFLARE_SETUP.md](./CLOUDFLARE_SETUP.md)** - Cloudflare Tunnel setup
- **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Quick command reference

---

## ✅ Checklist

### Development
- [x] Docker Compose configuration
- [x] Local development setup
- [x] Service health checks
- [x] API Gateway routing

### Production
- [x] Production Docker Compose
- [x] Unique port configuration (8765)
- [x] Production Nginx config
- [x] Rate limiting
- [x] CORS configuration
- [x] Security headers
- [x] Health checks
- [x] Log rotation
- [x] Deployment scripts
- [x] Documentation

### Deployment
- [ ] Deploy to server
- [ ] Configure Cloudflare Tunnel
- [ ] Test all endpoints
- [ ] Set up monitoring
- [ ] Configure alerts

---

**Ready for production deployment! 🚀**
