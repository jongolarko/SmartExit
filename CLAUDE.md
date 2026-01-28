# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SmartExit is a retail store exit management system with customer self-checkout, Razorpay payment processing, QR-based exit verification, and admin analytics. It's a monorepo with a Node.js/Express backend and Flutter mobile app.

## Build & Run Commands

### Backend
```bash
cd backend
npm install          # Install dependencies
npm start            # Production (port 5000)
npm run dev          # Development with --watch
```

### Flutter App
```bash
cd app
flutter pub get      # Get dependencies
flutter run          # Run on device/emulator
flutter build apk    # Build Android
flutter build ios    # Build iOS
```

### Database (PostgreSQL via Docker)
```bash
docker-compose up -d postgres     # Start database
docker-compose down               # Stop
docker-compose down -v            # Reset (delete data)

# Connect to DB
docker exec -it smartexit-db psql -U smartexit -d smartexit_db
```

## Architecture

```
┌─────────────────┐     HTTP/WebSocket     ┌─────────────────┐
│  Flutter App    │ ───────────────────────│  Express API    │
│  (Riverpod)     │                        │  (Port 5000)    │
└─────────────────┘                        └────────┬────────┘
                                                    │
                                           ┌────────▼────────┐
                                           │   PostgreSQL    │
                                           │   (Port 5432)   │
                                           └─────────────────┘
```

### Backend Structure (`/backend`)
- `src/controllers/` - Business logic (auth, cart, payment, exit, security, admin)
- `src/routes/` - API endpoint definitions
- `src/middleware/` - JWT auth, error handling, validation
- `src/config/` - Database pool, Razorpay client, Socket.io setup
- `src/services/` - OTP generation/verification
- `migrations/` - SQL schema with seed data

### Flutter App Structure (`/app/lib`)
- `providers/` - Riverpod state management (auth_provider, cart_provider)
- `services/` - API client, Socket.io, secure storage, config
- `screens/` - Role-based UI (customer/, security/, admin/)
- `core/theme/` - Design system tokens (colors, typography, spacing)
- `core/widgets/` - Reusable components (buttons, cards, inputs, scanner)

## Key Technical Details

### Authentication Flow
OTP-based (phone number) → JWT access token (15min) + refresh token (7 days) → Role-based routing (customer/security/admin)

### Real-time Events (Socket.io)
- `cart:updated`, `exit:request`, `exit:decision`, `order:new`, `fraud:alert`
- Room-based routing by role and user ID

### API Base Routes
- `/api/auth` - Register, OTP send/verify
- `/api/cart` - Cart CRUD operations
- `/api/payment` - Razorpay order creation, verification, webhooks
- `/api/exit` - Exit token generation and status
- `/api/security` - QR verification, exit approval
- `/api/admin` - Dashboard, orders, users, products, logs

### Database
11 tables with UUID primary keys. Key tables: `users`, `carts`, `cart_items`, `orders`, `order_items`, `gate_access`. Schema in `backend/migrations/001_initial_schema.sql`.

### Environment Variables (backend/.env)
Required: `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_PORT`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`

### Flutter Config
API URLs configured in `app/lib/services/config_service.dart` (defaults: localhost:5000)

## Tech Stack

**Backend**: Node.js, Express 5, PostgreSQL 16, Socket.io, JWT, Razorpay SDK, Joi validation, Winston logging

**Frontend**: Flutter 3.10+, Riverpod, http, socket_io_client, flutter_secure_storage, mobile_scanner, qr_flutter, fl_chart
