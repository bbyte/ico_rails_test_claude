# RSS Reader

A Rails 8 JSON API + React SPA that parses RSS feeds on demand. The app integrates with a separate Go microservice (`rss_service`) for the actual feed parsing, and delivers results in real time via ActionCable WebSockets.

---

## Architecture

### Dual-mode operation

Every feed submission checks whether Redis is reachable at request time and picks a path accordingly:

| Mode | Redis | Response | How results arrive |
|---|---|---|---|
| **Full** | Available | `202 Accepted` | ActionCable push after `rss_service` finishes |
| **Fallback** | Down | `201 Created` | Inline in the response body (synchronous HTTP poll) |

`ModeDetector.current` performs a Redis `PING` on every `POST /api/v1/feeds`. If Redis is unreachable the app degrades gracefully to synchronous mode without any user-visible error.

### Full-mode data flow

```
Browser → POST /api/v1/feeds
  → Rails creates FeedRequest (status: pending)
  → RedisStreamProducer publishes to rss:commands stream
  → 202 { status: "pending" } returned immediately

rss_service reads rss:commands
  → fetches + parses RSS feeds
  → writes result to rss:results stream

Rails stream consumer thread (XREADGROUP loop)
  → reads from rss:results
  → persists FeedItem records via insert_all
  → updates FeedRequest status
  → ActionCable.server.broadcast("feed_#{user_id}", …)

Browser FeedChannel receives broadcast
  → React updates FeedList in place
```

### Fallback-mode data flow

```
Browser → POST /api/v1/feeds
  → Rails calls RssServiceClient#parse (HTTP, polls /jobs/:id up to 10×)
  → persists FeedItems inline
  → 201 { status: "done", items: […] } returned
```

### Authentication

Devise manages user sessions via a cookie. On sign-in, Rails also sets an `httpOnly` `rss_jwt` cookie containing a pre-issued JWT — this cookie is forwarded transparently to `rss_service` and never exposed to JavaScript.

ActionCable connections are authenticated via `env["warden"]` (same session cookie used for HTTP requests).

---

## Stack

| Layer | Technology |
|---|---|
| Backend | Rails 8.1, Ruby 4.0 |
| Database | PostgreSQL 16 |
| Cache / Streams | Redis 7 |
| Auth | Devise |
| Views | Slim (layout shell only) |
| Frontend build | Vite + `vite_rails` |
| Frontend framework | React 19 |
| UI | Bootstrap 5 |
| RSS parsing | Go microservice (`rss_service`) |
| Real-time | ActionCable over WebSocket |
| Rails tests | RSpec, FactoryBot, Capybara (Selenium + rack_test) |
| JS tests | Jest, React Testing Library |

---

## Prerequisites

- Ruby 4.0 (Homebrew keg-only: `/opt/homebrew/opt/ruby/`)
- Node.js + npm
- PostgreSQL
- Redis
- Chrome + ChromeDriver (for browser feature specs)
- Docker + Docker Compose (for integration tests and full stack)

> **macOS PATH note:** Homebrew Ruby is keg-only and not on `PATH` by default. Add this to `~/.zshrc`:
> ```bash
> export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"
> ```

---

## Local development setup

```bash
cd rss_frontend

# Install dependencies
bundle install
npm install

# Create and migrate the database
bundle exec rails db:create db:migrate

# Start the Vite dev server (separate terminal)
bin/vite dev

# Start Rails
bundle exec rails server
```

The app is available at `http://localhost:3000`. Vite runs on port 3036 and hot-reloads assets automatically.

---

## Docker Compose (full stack)

Starts PostgreSQL, Redis, `rss_service`, and the Rails app together:

```bash
# From the project root (ico_rails_test_sonnet/)
docker compose up -d
```

The Rails container listens on `http://localhost:3000`. The stream consumer thread is enabled automatically (`ENABLE_STREAM_CONSUMER=1`).

### Required secrets

Copy `config/master.key` (or set `RAILS_MASTER_KEY`) before running in Docker. The `rss_service` also requires EC key files for JWT verification — see its own README.

---

## Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `DATABASE_URL` | — | PostgreSQL connection string |
| `REDIS_URL` | `redis://localhost:6379/1` | ActionCable adapter + stream consumer |
| `RSS_SERVICE_URL` | `http://rss_service:8080` | Go microservice base URL |
| `RSS_SERVICE_JWT` | — | JWT placed in the `rss_jwt` cookie at login |
| `ENABLE_STREAM_CONSUMER` | — | Set to `"1"` to start the XREADGROUP thread outside production |
| `DISABLE_STREAM_CONSUMER` | — | Set to `"1"` to suppress the thread even in production |

---

## API reference

All endpoints are under `/api/v1/`. Auth uses the Devise session cookie.

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/api/v1/users/sign_in` | — | Sign in; sets session + `rss_jwt` cookie |
| `DELETE` | `/api/v1/users/sign_out` | ✓ | Sign out; clears both cookies |
| `POST` | `/api/v1/feeds` | ✓ | Submit URLs for parsing |
| `GET` | `/api/v1/feed_items` | ✓ | Cached items for the current user, sorted by `publish_date DESC` |
| `GET` | `/api/v1/health` | — | Returns `{"mode":"full"}` or `{"mode":"fallback"}` |

### POST /api/v1/feeds

**Request body:**
```json
{ "urls": ["https://example.com/feed.rss"] }
```

**Full mode response (202):**
```json
{ "feed_request_id": 1, "job_id": "uuid", "status": "pending", "mode": "full" }
```

**Fallback mode response (201):**
```json
{
  "feed_request_id": 1,
  "job_id": "uuid",
  "status": "done",
  "mode": "fallback",
  "items": [{ "title": "…", "link": "…", "publish_date": "2026-05-23", … }]
}
```

### ActionCable

Connect to `/cable`. Subscribe to `FeedChannel`. When the stream consumer processes a result, it broadcasts to `"feed_#{user_id}"`:

```json
{
  "feed_request_id": 1,
  "status": "done",
  "items": [{ "title": "…", "link": "…", "publish_date": "2026-05-23", … }],
  "errors": []
}
```

---

## Database models

### User
Devise-managed. Has `jwt_jti` for blocklist support.

### FeedRequest
Tracks one parse job. Columns: `user_id`, `job_id` (UUID), `urls` (PostgreSQL `text[]`), `status` (`pending` → `processing` → `done` / `failed`), `mode` (`full` / `fallback`).

### FeedItem
One cached RSS entry. Unique on `(feed_request_id, link)`. `publish_date` is a `date` column. Sorted `publish_date DESC` everywhere.

---

## Running tests

### Test database setup (first time)

```bash
bundle exec rails db:create db:schema:load RAILS_ENV=test
```

If the test database has stale state (e.g. leftover Capybara connections blocking a drop):

```bash
pkill -f "puma"
bundle exec rails db:drop db:create db:schema:load RAILS_ENV=test
```

### Rails (RSpec)

```bash
# All specs
bundle exec rspec

# By layer
bundle exec rspec spec/models
bundle exec rspec spec/services
bundle exec rspec spec/controllers
bundle exec rspec spec/channels
bundle exec rspec spec/requests

# Feature specs — no Docker needed
bundle exec rspec spec/features --tag '~integration'

# Integration specs — requires docker compose up -d
bundle exec rspec spec/features --tag integration

# Single file
bundle exec rspec spec/models/feed_request_spec.rb
```

### JavaScript (Jest)

```bash
# All tests
npm test

# Single file
npx jest LoginForm
npx jest useFeedChannel
```

### Test suite overview

| Suite | Driver | What it covers |
|---|---|---|
| Models | — | Validations, associations, scopes |
| Services | WebMock | `ModeDetector`, `RedisStreamProducer`, `RssServiceClient` |
| Controllers | rack_test | API request/response, auth enforcement |
| Channels | ActionCable test adapter | `FeedChannel` subscribe / reject |
| Requests | rack_test | Full HTTP cycle for all endpoints |
| Features (non-integration) | Selenium + rack_test | Auth flow, feed item display |
| Features (integration) | Selenium | Full ActionCable mode, fallback mode |
| Jest | jsdom | `LoginForm`, `FeedForm`, `FeedList`, `FeedItem`, `useFeedChannel` |

---

## Frontend structure

```
app/frontend/
├── entrypoints/
│   └── application.jsx     # Vite entry — imports Bootstrap, mounts <App />
├── api/
│   └── client.js           # fetch wrapper; reads CSRF token from <meta> tag
├── cable.js                # ActionCable consumer singleton
├── hooks/
│   └── useFeedChannel.js   # subscribes/unsubscribes to FeedChannel on mount
└── components/
    ├── App.jsx             # auth state machine; wires FeedChannel broadcasts
    ├── auth/
    │   └── LoginForm.jsx
    └── feeds/
        ├── FeedForm.jsx    # URL inputs + submit
        ├── FeedList.jsx    # renders per-request groups, sorted by publish_date
        ├── FeedItem.jsx    # card with title, source, date, description, link
        └── shared/
            ├── StatusBadge.jsx   # renders data-status attribute (Capybara target)
            └── ErrorBanner.jsx
```

The SPA mounts into `#root` in `app/views/layouts/application.html.slim`. Slim is used only for the layout shell; all UI is React.

On initial load, `App.jsx` calls `GET /api/v1/feed_items`. Success means the user has a valid session and previously cached items are rendered immediately. A 401 shows the login form.

---

## Stream consumer

`config/initializers/stream_consumer.rb` starts a plain `Thread.new` (not Sidekiq) on app boot when `ENABLE_STREAM_CONSUMER=1` or in production. It runs a blocking `XREADGROUP` loop on the `rss:results` Redis Stream, consumer group `rss-rails-workers`. On each message:

1. Finds the `FeedRequest` by `job_id`
2. Bulk-inserts `FeedItem` records via `insert_all` (duplicates skipped by unique index on `(feed_request_id, link)`)
3. Updates `FeedRequest#status`
4. Broadcasts to ActionCable on `"feed_#{user_id}"`
5. ACKs the message with `XACK`

Per-message errors are logged and skipped. Redis connection errors trigger a 5-second back-off and retry.
