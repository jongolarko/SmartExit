# SmartExit

Retail Store Exit Management System - A complete solution for self-checkout with secure exit verification.

## Project Structure

```
smartexit/
├── docker-compose.yml    # Docker services (PostgreSQL)
├── backend/              # Node.js Express API
│   ├── src/
│   ├── migrations/
│   └── package.json
├── app/                  # Flutter mobile application
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
└── docs/                 # Documentation
```

## Quick Start

### Prerequisites

- Docker Desktop
- Node.js 18+
- Flutter 3.x

### 1. Start Database

```bash
# Start PostgreSQL container (auto-runs migrations)
docker-compose up -d postgres

# Verify container is running
docker ps

# Check logs
docker-compose logs -f postgres
```

### 2. Start Backend

```bash
cd backend
npm install
npm start
```

Backend runs at `http://localhost:5000`

### 3. Run Flutter App

```bash
cd app
flutter pub get
flutter run
```

## Docker Commands

```bash
# Start database
docker-compose up -d postgres

# Stop database
docker-compose down

# Reset database (delete all data)
docker-compose down -v

# Connect to PostgreSQL shell
docker exec -it smartexit-db psql -U smartexit -d smartexit_db
```

## Database Credentials

| Setting | Value |
|---------|-------|
| Host | localhost |
| Port | 5432 |
| Database | smartexit_db |
| User | smartexit |
| Password | smartexit_dev_2024 |

## API Endpoints

- `POST /api/auth/register` - Start registration
- `POST /api/auth/verify-otp` - Verify OTP
- `POST /api/auth/login` - Request OTP login
- `GET /api/cart` - Get user's cart
- `POST /api/cart/add` - Add item to cart
- `POST /api/payment/create-order` - Create Razorpay order
- `GET /api/exit/token` - Get exit token/QR
- `POST /api/security/verify` - Verify exit token

## Environment Variables

Copy `backend/.env.example` to `backend/.env` and update values as needed.
