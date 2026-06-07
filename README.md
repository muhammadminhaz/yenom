# Yenom — Islamic Money Manager

> **"Yenom"** is a mobile-first, offline-first personal finance app built with Islamic finance principles at its core.

---

## What This App Does

Yenom lets you track income and expenses with categories rooted in Islamic finance (Sadaqah, Zakat, Fitrana). All your data lives locally on your phone — no account required to use it. When you're ready, tap **Sync** in Settings to back up to the cloud. If you ever reset your phone, tap **Restore** to get everything back.

An AI agent (powered by Claude) reads your Gmail and SMS in the background and surfaces one-tap transaction suggestions. You review them, tap **Add**, and the pre-filled form is waiting for you. No manual typing for routine bank notifications.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Flutter Mobile App                      │
│  Hive (local DB) ←→ Riverpod state ←→ UI screens        │
│                        │                                 │
│               (user-triggered only)                      │
│                        ↓                                 │
│            Spring Boot REST API (:8080)                  │
│   PostgreSQL · Redis cache · Kafka · JWT auth            │
│                        │                                 │
│              Claude AI (Haiku 4.5)                       │
│           Gmail OAuth2 · SMS webhook                     │
└─────────────────────────────────────────────────────────┘
```

**Core principle:** The app works 100% offline. The backend is a backup vault, not a real-time API. Every feature works in Hive first; the backend is only touched when the user explicitly taps Sync.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile | Flutter 3, Riverpod, Hive (offline DB) |
| Backend | Spring Boot 4.0.1, Java 25 |
| Database | PostgreSQL 16, Flyway migrations |
| Cache | Redis |
| Messaging | Apache Kafka |
| Auth | JWT (access + refresh tokens) |
| AI | Claude `claude-haiku-4-5` via Anthropic REST API |
| Gmail | Google OAuth2 (direct HTTP, no SDK) |
| Frontend | Next.js 16 (not yet built out) |

---

## Project Structure

```
yenom/
├── mobile/                        # Flutter app
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   │   ├── app_constants.dart       # AppColors, spacing, typography
│   │   │   │   └── categories.dart          # Islamic + regular categories
│   │   │   ├── models/
│   │   │   │   ├── transaction_model.dart   # Hive typeId 1
│   │   │   │   ├── transaction_model.g.dart # Manually maintained adapter
│   │   │   │   ├── suggestion_model.dart    # Hive typeId 4
│   │   │   │   └── suggestion_model.g.dart  # Manually maintained adapter
│   │   │   ├── providers/
│   │   │   │   ├── theme_provider.dart
│   │   │   │   └── suggestion_provider.dart # StateNotifier
│   │   │   ├── services/
│   │   │   │   ├── api_service.dart         # Dio + JWT interceptor
│   │   │   │   ├── auth_api_service.dart    # Login, register, logout
│   │   │   │   ├── database_service.dart    # All Hive operations
│   │   │   │   ├── sync_service.dart        # Cloud backup & restore
│   │   │   │   ├── suggestion_api_service.dart
│   │   │   │   └── sms_service.dart         # Android SMS reading
│   │   │   └── utils/
│   │   │       └── app_logger.dart          # d/i/w/e log levels
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart        # Offline fallback login
│   │   │   │   └── register_screen.dart
│   │   │   ├── dashboard/
│   │   │   │   ├── dashboard_screen.dart    # Main screen
│   │   │   │   ├── add_transaction_screen.dart  # Add / Edit / Prefill
│   │   │   │   ├── transactions_list_screen.dart
│   │   │   │   └── transaction_detail_screen.dart
│   │   │   ├── suggestions/
│   │   │   │   ├── suggestions_screen.dart
│   │   │   │   ├── suggestion_card_widget.dart
│   │   │   │   └── suggestion_banner_widget.dart
│   │   │   ├── settings/
│   │   │   │   ├── settings_screen.dart     # Sync, Gmail, SMS, theme
│   │   │   │   └── ios_sms_setup_screen.dart
│   │   │   └── profile/
│   │   └── widgets/
│   │       ├── neumorphic_container.dart
│   │       ├── neumorphic_button.dart
│   │       └── neumorphic_text_field.dart
│   ├── test/
│   │   ├── categories_test.dart        (20 tests)
│   │   ├── database_service_test.dart  (18 tests)
│   │   ├── auth_api_service_test.dart  (10 tests)
│   │   ├── sync_service_test.dart      (18 tests)
│   │   ├── suggestion_model_test.dart  (10 tests)
│   │   └── helpers/test_helpers.dart
│   └── android/app/src/main/AndroidManifest.xml
│
├── backend/
│   └── src/main/java/.../yenombackend/
│       ├── config/
│       │   ├── SecurityConfig.java
│       │   ├── CacheConfig.java
│       │   └── RateLimitingFilter.java
│       ├── controller/
│       │   ├── AuthController.java
│       │   ├── TransactionController.java
│       │   ├── SuggestionController.java    # /api/suggestions
│       │   └── GmailController.java         # /api/gmail
│       ├── service/
│       │   ├── AuthService.java
│       │   ├── TransactionService.java
│       │   ├── SuggestionService.java
│       │   ├── GmailService.java
│       │   └── ClaudeParsingService.java    # Anthropic API
│       ├── kafka/
│       │   ├── SuggestionParsingProducer.java
│       │   └── SuggestionParsingConsumer.java
│       ├── model/
│       │   ├── User.java
│       │   ├── Transaction.java
│       │   ├── TransactionSuggestion.java
│       │   └── GmailToken.java
│       ├── repository/
│       ├── dto/
│       ├── security/
│       └── resources/
│           └── db/migration/
│               ├── V1__create_users_table.sql
│               ├── V2__create_transactions_table.sql
│               ├── V3__create_transaction_suggestions_table.sql
│               └── V4__create_gmail_tokens_table.sql
│
└── docker-compose.yml
```

---

## Features Built

### Phase 1 — Core Expense / Income Tracker

The foundation of the app. Everything else is built on top of this.

- **Add/Edit/Delete transactions** with amount, description, date, category, currency
- **Islamic categories** as first-class citizens — Sadaqah, Zakat, Fitrana shown with ☽ crescent icon
- **10 currencies** supported (USD, EUR, GBP, BDT, SAR, AED, CAD, AUD, JPY, INR)
- **Dashboard** — total balance, monthly income vs expenses, monthly save %, top spending category
- **Transaction list** — type filter chips, category chips, search bar, swipe-to-delete, tap for details
- **Transaction detail screen** — full view with edit + delete actions
- **AppLogger** — d/i/w/e log levels, suppressed in release builds

### Phase 2 — Backend Authentication

- **Real JWT auth** — login and register hit the Spring Boot backend
- **Offline fallback login** — if the network is unreachable but you've logged in before, the app lets you in with a "Working offline" notice
- **`isSynced` field** added to every transaction (HiveField 11, default `false`) so the app knows what needs to be uploaded
- **`ApiException`** wraps Dio errors into human-readable messages (timeout, no internet, server error)

### Phase 3 — Cloud Backup & Sync

- **Sync to Cloud** — uploads all unsynced transactions one by one; marks each as synced on success; shows count and any errors
- **Restore from Cloud** — clears local data, re-downloads all transactions from the backend in pages of 50; intended for phone-reset recovery
- **Settings screen** — user card, last-synced timestamp, unsynced badge count, Sync/Restore buttons with loading states, confirmation dialog before Restore, dark/light theme toggle, Sign Out

### Phase 4 — Database Migrations (Backend)

Two Flyway migrations added to the backend:

**V3 — `transaction_suggestions`**
```sql
id, user_id (FK→users), source (GMAIL|SMS), raw_message,
amount, currency, transaction_date, description, category,
type (INCOME|EXPENSE), is_haram, haram_reason,
ai_confidence, status (PENDING|ACCEPTED|REJECTED),
created_at, updated_at, expires_at (7-day TTL)
```

**V4 — `gmail_tokens`**
```sql
id, user_id (FK→users, UNIQUE), access_token, refresh_token,
token_expiry, gmail_email, created_at, updated_at
```

### Phase 5 — AI Transaction Suggestion Agent

#### How it works

```
Gmail inbox / Android SMS
        │
        ▼
  POST /api/gmail/sync
  POST /api/suggestions/sms
        │
        ▼
  Kafka topic: transaction-parsing-requests
        │
        ▼
  SuggestionParsingConsumer
        │
        ▼
  ClaudeParsingService
  → calls Anthropic /v1/messages (tool_use)
  → extracts: amount, currency, date, description, category, type
  → flags isHaram for: alcohol, gambling, pork, adult content
  → rejects if confidence < 0.5
        │
        ▼
  TransactionSuggestion saved (status = PENDING)
        │
        ▼
  Mobile polls GET /api/suggestions
  → Banner on dashboard shows "N new suggestions"
        │
        ▼
  User taps suggestion → Add Transaction (pre-filled)
  User accepts → real Transaction row created in DB
  User rejects → status = REJECTED, removed from list
```

#### Backend endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/suggestions` | JWT | Paginated PENDING suggestions |
| PATCH | `/api/suggestions/{id}/accept` | JWT | Accepts suggestion, creates Transaction |
| PATCH | `/api/suggestions/{id}/reject` | JWT | Marks as REJECTED |
| DELETE | `/api/suggestions/{id}` | JWT | Hard delete |
| POST | `/api/suggestions/sms` | JWT | Submit raw SMS text for parsing |
| GET | `/api/gmail/auth-url` | JWT | Returns Google OAuth2 URL |
| GET | `/api/gmail/callback` | Public | OAuth redirect handler |
| POST | `/api/gmail/sync` | JWT | Triggers Gmail inbox fetch |
| POST | `/api/gmail/disconnect` | JWT | Removes stored Gmail tokens |
| GET | `/api/gmail/status` | JWT | Returns `{connected: bool}` |

#### Mobile — Suggestion UI

- **Dashboard banner** — appears between the summary row and Recent Transactions when suggestions are pending; hidden when count is 0; shows amber dot if any suggestion has a haram flag
- **Suggestions screen** — list of neumorphic cards with source badge (GMAIL / SMS), amount, description, Islamic ☽ for Islamic categories, amber "Check permissibility" warning for haram content
- **Swipe to reject** — swipe left to dismiss a suggestion
- **Accept flow** — tapping Add marks it accepted on the backend then opens AddTransactionScreen with all fields pre-filled
- **Settings → AI Suggestions** section — Connect Gmail button (opens browser for OAuth), Sync inbox, Disconnect; Set up SMS Notifications (Android: permission grant; iOS: wizard)
- **iOS SMS Setup wizard** — 7-step guide with copy-able webhook URL and JWT token for creating an iOS Shortcuts automation

#### Claude integration

The `ClaudeParsingService` calls `https://api.anthropic.com/v1/messages` directly using Spring's `RestClient`. It uses the `tool_use` feature to get guaranteed structured JSON output — no regex parsing of free-form text. The tool schema enforces all required fields and enum values.

---

## Islamic Finance Features

| Feature | Implementation |
|---------|---------------|
| Islamic categories | Sadaqah, Zakat, Fitrana are first-class categories (not just labels), grouped separately in the category picker, shown with ☽ icon everywhere |
| Haram flagging | Claude flags transactions involving alcohol, gambling, pork, adult content — amber warning badge on suggestion card prompts the user to reconsider before accepting |
| Greeting | Dashboard says "As-salamu alaykum," instead of "Hello" |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Java 25 + Maven
- Docker + Docker Compose
- A PostgreSQL instance (or use Docker Compose)
- A Kafka instance (or use Docker Compose — see below)

### 1. Clone and configure environment

```bash
git clone <repo-url>
cd yenom
cp .env.example .env   # fill in the values below
```

**Required environment variables (`.env`)**:

```env
# Database
DB_NAME=yenom
DB_USER=yenom_user
DB_PASSWORD=your_password

# JWT
JWT_SECRET=your_256_bit_secret_here

# AI (Phase 5)
ANTHROPIC_API_KEY=sk-ant-...

# Gmail OAuth2 (Phase 5)
# Create a project at console.cloud.google.com
# Enable Gmail API → OAuth consent screen → Create OAuth 2.0 Client ID (Web)
# Add redirect URI: http://localhost:8080/api/gmail/callback
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_REDIRECT_URI=http://localhost:8080/api/gmail/callback

# Kafka
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
```

### 2. Start infrastructure

```bash
docker-compose up -d
```

This starts PostgreSQL, Redis, and the backend. Add Kafka to `docker-compose.yml` if needed:

```yaml
kafka:
  image: confluentinc/cp-kafka:latest
  environment:
    KAFKA_BROKER_ID: 1
    KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
    KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
  ports:
    - "9092:9092"
```

### 3. Run the backend

```bash
cd backend
mvn spring-boot:run
```

Flyway will run all migrations automatically on startup. The API is available at `http://localhost:8080`.

Swagger UI: `http://localhost:8080/swagger-ui.html`

### 4. Run the mobile app

```bash
cd mobile
flutter pub get
flutter run
```

For Android emulator, the backend URL is automatically set to `http://10.0.2.2:8080`. For iOS simulator, it uses `http://localhost:8080`.

### 5. Run tests

```bash
# Mobile (Flutter)
cd mobile
flutter test

# Backend (Maven)
cd backend
mvn test
```

---

## API Reference

### Auth

| Method | Path | Body | Description |
|--------|------|------|-------------|
| POST | `/api/auth/register` | `{username, email, password, firstName, lastName, city?, country?}` | Create account |
| POST | `/api/auth/login` | `{username, password}` | Returns JWT |
| GET | `/api/me` | — | Current user profile |

### Transactions

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/transactions/create` | Create transaction |
| GET | `/api/transactions` | Paginated list (`?page=0&size=20`) |
| PUT | `/api/transactions/{id}` | Update transaction |
| DELETE | `/api/transactions/{id}` | Delete transaction |

### Suggestions

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/suggestions` | PENDING suggestions (paginated) |
| PATCH | `/api/suggestions/{id}/accept` | Accept → creates Transaction |
| PATCH | `/api/suggestions/{id}/reject` | Dismiss |
| DELETE | `/api/suggestions/{id}` | Hard delete |
| POST | `/api/suggestions/sms` | Submit SMS text `{text: "..."}` |

### Gmail

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/gmail/auth-url` | Returns Google OAuth URL |
| GET | `/api/gmail/callback` | OAuth redirect (public) |
| POST | `/api/gmail/sync` | Fetch inbox → Kafka |
| POST | `/api/gmail/disconnect` | Remove tokens |
| GET | `/api/gmail/status` | `{connected: bool}` |

---

## Data Model

### Transaction (mobile Hive + backend PostgreSQL)

| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Time-based UUID v1 |
| userId | UUID | |
| amount | Decimal | > 0 |
| currency | String | ISO-4217, e.g. USD |
| transactionDate | Date | |
| description | String | max 255 |
| category | String | From AppCategories list |
| type | Enum | INCOME \| EXPENSE |
| status | Enum | PENDING \| COMPLETED \| CANCELLED |
| isSynced | Bool | Mobile-only; false = not yet uploaded |

### TransactionSuggestion (backend only, cached in Hive on mobile)

| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| source | String | GMAIL \| SMS |
| rawMessage | Text | Original message text |
| amount | Decimal | Claude-extracted |
| isHaram | Bool | Claude-flagged |
| haramReason | String | e.g. "Alcohol purchase" |
| aiConfidence | Decimal | 0.0 – 1.0 |
| status | String | PENDING → ACCEPTED \| REJECTED |
| expiresAt | Timestamp | 7 days after creation |

---

## Transaction Categories

**Expense**
`Food & Dining` · `Transport` · `Shopping` · `Bills & Utilities` · `Healthcare` · `Education` · `Housing / Rent` · `Entertainment` · `Fitness` · `Travel` · `Gifts` · `Other`

**Islamic Expense** *(shown with ☽)*
`Sadaqah` · `Zakat` · `Fitrana`

**Income**
`Salary` · `Freelance` · `Business` · `Investment (Halal)` · `Rental` · `Gift` · `Other Income`

---

## iOS SMS Note

iOS does not allow apps to read SMS directly. The workaround is an **iOS Shortcuts automation** that the user sets up once:

1. Open Shortcuts → Automation → New → Message Received
2. Add action: Get Text from Shortcut Input
3. Add action: Get contents of URL → POST `https://your-api/api/suggestions/sms`
   - Header: `Authorization: Bearer <your JWT>`
   - Body (JSON): `{"text": [Shortcut Input]}`

The Settings screen in the app walks through this step-by-step with copy-able URL and token values.

---

## Testing

| Test file | Count | What it covers |
|-----------|-------|---------------|
| `categories_test.dart` | 20 | `AppCategories` — isIslamic, iconFor, symbolFor, forTransactionType |
| `database_service_test.dart` | 18 | All DatabaseService CRUD methods |
| `auth_api_service_test.dart` | 10 | ApiException.fromDio all error types, isSynced/copyWith |
| `sync_service_test.dart` | 18 | SyncResult fields, getUnsyncedTransactions, markAsSynced, auth guards |
| `suggestion_model_test.dart` | 10 | fromJson, isExpense, haram fields, typeId |
| `ClaudeParsingServiceTest.java` | 10 | parseResponse via reflection — no live API calls |

---

## Planned / Future

- Zakat nisab calculator — prompts when total savings exceed the nisab threshold
- Push notifications for new suggestions (Firebase)
- Next.js web dashboard (existing `frontend/` folder)
- Biometric lock for the app
- Recurring transactions
- Export to CSV / PDF

---

## License

Private project — not licensed for redistribution.
