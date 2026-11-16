# CalWatt

CalWatt includes a Flutter mobile app and a separate React web portal backed by a shared Node.js API and MySQL database. Both clients use the same user accounts, appliances, simulation days, administrator-managed electricity rates, and saved consumption estimates.

## Web system architecture

```text
React + Vite browser app
        │ same-origin /api requests (Vite proxy in development)
        ▼
Express REST API ── HTTP-only server session + CSRF protection
        │ parameterized MySQL queries
        ▼
MySQL 8 (users, appliances, rates, estimates, simulations, audit trail)
```

The server is authoritative for persisted records and role checks. A user only sees or changes their own records; administrators access system reports, user account status, rate history, and audit actions. Consumption is estimated, not measured by an electricity meter. Each saved estimate records its applied rate so past costs remain reproducible.

New user accounts and the development sample account start with six editable example appliances matching the Flutter app. Estimates use the wattage, entered hours, quantity, selected date's electricity rate, and the saved record's rate snapshot; electricity usage is user-entered and is not read from a physical meter.

Mobile and web dashboard projections use the same schedule-aware estimate: per scheduled day, `kWh = watts / 1000 × daily operating hours × quantity`; weekly use is averaged over seven days, and the 30-day projection is that average multiplied by 30. Appliances marked off are excluded. The web calculator is a separate actual-use estimate: it applies the hours and quantity entered for the selected date, regardless of the appliance's weekly schedule.

The React portals are responsive across desktop and phone browsers, with a shared emerald brand and logo, compact dashboard cards, and labeled stacked tables. On phones, the user portal's bottom navigation matches the Flutter app's Dashboard, Appliances, Simulate, Analytics, and Settings sections; Calculator and Consumption history remain available in the navigation drawer.

## Requirements

- Node.js 20.19+ (or 22.12+), npm
- MySQL 8.0 running locally (the existing Windows MySQL80 service works)
- Flutter/Dart only if you also want to run the existing mobile app

## Windows setup

### One-command startup

After completing the one-time MySQL and environment setup below, double-click `start.bat` (or run `.\start.bat` from the repository root). It checks Node.js/npm, starts the MySQL Windows service if needed, installs missing npm packages, runs the database migration and development seed, starts the API and frontend in separate terminal windows, waits for both health checks, configures Android emulator API forwarding, and launches the Flutter app when a running emulator and Flutter are available. It also opens `http://127.0.0.1:5173`.

Keep both terminal windows open while using CalWatt. Close those windows to stop the services. The launcher creates `backend\.env` from the example on its first run and exits with setup instructions; complete the database setup and replace all example secrets/passwords before running it again. It will not automatically create a MySQL database or database user, because those operations require database administrator credentials.

### 1. Create a database and restricted application user

Sign into the local MySQL server using your MySQL administrator account, then run:

```sql
CREATE DATABASE calwatts CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER 'calwatts_app'@'localhost' IDENTIFIED BY 'use-a-unique-local-password';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX, REFERENCES
  ON calwatts.* TO 'calwatts_app'@'localhost';
FLUSH PRIVILEGES;
```

Choose a unique database password and put the same value in the local backend environment file. Do not commit that file.

### 2. Configure the backend

In PowerShell from the repository root:

```powershell
Copy-Item backend\.env.example backend\.env
```

Edit `backend\.env`: set a random `SESSION_SECRET` of at least 32 characters, the same `DB_PASSWORD` used when creating the MySQL user, and strong local development account passwords. Keep `COOKIE_SECURE=false` for local HTTP development; production always requires secure cookies over HTTPS.

Then start everything with:
```powershell
.\start.bat
```

The development seed creates an administrator and a sample regular user from the values in `backend\.env`. It is blocked unless `NODE_ENV=development`. The example account credentials are for local development only; change them before seeding and never use them in production.

The migration creates the schema and initializes the default electricity rate to PHP 12/kWh only when no rate exists. It is safe to rerun.

### Manual startup (optional)

If you prefer separate manual startup:

```powershell
# Terminal 1
cd backend
npm ci
npm run migrate
npm run seed:dev
npm run dev

# Terminal 2
cd frontend
npm ci
npm run dev
```

Open `http://127.0.0.1:5173`. The Vite development server proxies `/api` requests to the local API, allowing the browser to use the session cookie without cross-origin configuration.

### 4. Local development sign-in

Use the email and password values configured as `ADMIN_EMAIL`/`ADMIN_PASSWORD` or `SAMPLE_USER_EMAIL`/`SAMPLE_USER_PASSWORD` in `backend\.env`.

## API overview

All API routes use `/api`. Mutating requests require a CSRF token obtained from `GET /api/auth/csrf`; the React client handles it automatically. Responses use JSON. Session cookies are HTTP-only, same-site, and expire after four hours.

| Area | Routes |
|---|---|
| Authentication | `GET /auth/csrf`, `GET /auth/me`, `POST /auth/register`, `POST /auth/login`, `POST /auth/logout` |
| User profile | `GET /profile`, `PUT /profile`, `PUT /change-password` |
| User data | `GET /dashboard`, `GET /rate?date=YYYY-MM-DD`, appliance CRUD at `/appliances`, paginated history at `/consumption`, `POST /consumption`, simulation at `/simulation` |
| Administration | `/admin/dashboard`, `/admin/users`, `/admin/consumption`, `/admin/reports`, `/admin/rates`, `/admin/audit-logs` |
| Health | `GET /health` (includes a live MySQL connectivity check) |

IDs, dates, roles, ownership, and request values are validated server-side; user ownership always comes from the authenticated session. SQL operations use bound parameters.

## Database tables

- `users`: user/admin identity, password hashes, account status
- `appliances`: household appliance details and configured hours
- `electricity_rates`: rate timeline and administrator attribution
- `consumption_records`: dated calculation snapshots, including appliance and rate snapshots
- `simulation_days`, `simulation_usages`: hypothetical daily configurations
- `audit_logs`: administrator rate and account-status actions
- `user_sessions`: server-side Express session storage

## Tests and production build

```powershell
cd backend
npm test
```

In another terminal:

```powershell
cd frontend
npm run build
```

The frontend must be served from the same site as the API in production (or use a trusted origin and configure session cookies, HTTPS, and CORS accordingly). Configure MySQL backups and a production session secret before deployment.

## Existing Flutter app

The Flutter app remains at the repository root. Sign in or register with a regular CalWatt user account; administrator accounts use the web portal. Mobile edits are saved locally and queued while offline, then synchronized when the connection returns or when you tap **Sync now** in Settings. Login requires an internet connection at least once. The mobile app also displays saved consumption history from the shared account.

To run it in the Android emulator:

```powershell
flutter pub get
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb reverse tcp:4000 tcp:4000
flutter run -d emulator-5554
```

`start.bat` sets up the `adb reverse` mapping and launches Flutter when it detects the Android SDK, an emulator, and Flutter on `PATH`. The default mobile API URL is `http://127.0.0.1:4000/api`; the reverse mapping makes that address reach the computer from the emulator. Local cleartext HTTP is allowed only in Android debug builds. For a release build, provide an HTTPS API URL with `--dart-define=CALWATT_API_BASE_URL=https://your-api.example/api`.
