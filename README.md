# Dispure Review Queue

## Features Implemented

- Webhook ingestion (Sidekiq)
- Idempotent + out-of-order safe
- State machine + reopen
- AASM with justification
- Evidence upload + required note
- ActiveStorage + validation
- Full audit trail (user + webhook)
- Polymorphic Actors for Audit logs
- RBAC (admin / reviewer / read_only)
- Pundit + policies
- Time-zone-aware UI timestamps
- Daily Volume Report
- Chart + table
- Time-to-Decision Report (p50/p90)
- Weekly grouping
- Beautiful Tailwind UI
- Login, queue, reports
- Docker + docker-compose
- Full stack + auto-setup
- End-to-end simulation script
- Webhook → file upload → reopen



## Quick Start (Docker — Recommended)

```bash
# 1. Clone the project
git clone https://github.com/dev-faraz/dispute_review_queue.git
cd dispute_review_queue

# 2. Copy and configure environment
cp .env.example .env
# Edit .env and set your DATABASE_PASSWORD

# 3. Install tailwind css

rails importmap:install (Enter no in case of any conflicts file)
rails tailwindcss:install

# 4. Start everything (first time builds images)
docker-compose up --build

```

## Default Users (created via seed file)

| Email                | Password | Role     | Time Zone |
|----------------------|----------|----------|-----------|
| admin@example.com    | password | Admin    |America/New_York
| reviewer@example.com | password | Reviewer |America/Los_Angeles
| readonly@example.com | password | Read-only|Europe/London


## Run the Full End-to-End Simulation
```bash
docker-compose exec web ./simulate_dispute_flow.rb
```
### This script:

- Logs in as reviewer
- Sends a webhook (creates dispute)
- Uploads a real file as evidence
- Reopens a lost dispute
- Prints beautiful colored output

## Manual Commands (inside container)

```bash
# Enter container
docker-compose exec web bash

# Rails console
bundle exec rails console

# Run migrations / seed
bundle exec rails db:migrate
bundle exec rails db:seed

# Reset everything
bundle exec rails db:drop db:create db:migrate db:seed
```

## Key URLs

| Page                       | URL      |
|----------------------------|----------|
| Dispute Queue              | http://localhost:3000 |
| Daily Volume Report        | http://localhost:3000/reports/daily_volume |
| Time to Decision (p50/p90) | http://localhost:3000/reports/daily_volume |
| Sidekiq Dashboard          | http://localhost:3000/sidekiq |


## Tech Stack
- Ruby 3.4 + Rails 8.0
- TailwindCSS (via Importmap — zero build step)
- PostgreSQL 16 + Redis
- Sidekiq for background jobs
- Devise + Pundit for auth & authorization
- AASM for state machine
- ActiveStorage (disk) for evidence files
- Docker + docker-compose (full stack with auto-setup)

