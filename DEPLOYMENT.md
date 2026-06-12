# Deploying Puzler

Production architecture:

| Piece              | Host                | Notes                                          |
| ------------------ | ------------------- | ---------------------------------------------- |
| Vue SPA            | Render Static Site  | `render.yaml`, builds `app/` → `dist/`         |
| Rails API          | Render (Docker)     | `render.yaml` Blueprint at the repo root       |
| PostgreSQL         | Render managed      | `DATABASE_URL` wired by the Blueprint          |
| Redis              | Render Key Value    | ActionCable now, Sidekiq later (`noeviction`)  |
| File storage       | Cloudflare R2       | already configured (`config/storage.yml`)      |
| Email              | SendGrid            | SMTP, key in production credentials            |
| Analytics          | Plausible           | cookieless, env-gated (`VITE_PLAUSIBLE_DOMAIN`)|

All compute/hosting lives on Render; R2 (avatars) and SendGrid (email) are
managed dependencies, not servers you run. The API and SPA are **separate
repos** (`puzler-api`, `puzler-vue`), so each carries its own `render.yaml`
Blueprint.

Suggested domains (substitute your own): SPA at `puzler.app`, API at `api.puzler.app`.

The app is env-driven, so nothing here requires code changes — only dashboard
config and the credential values you fill in.

---

## Prerequisites

- Both repos pushed to GitHub (`puzler-api`, `puzler-vue`).
- A Render account.
- A domain you control.
- `config/credentials/production.key` (in this repo) handy — its contents
  become `RAILS_MASTER_KEY`.

---

## Part A — Provision (two Blueprints, one per repo)

1. **API stack** — New → Blueprint → connect the **puzler-api** repo. Its
   `render.yaml` provisions `puzler-api` (web), `puzler-db` (Postgres), and
   `puzler-redis` (Key Value). Apply. `DATABASE_URL` and `REDIS_URL` wire
   automatically, and `bin/docker-entrypoint` runs `db:prepare` on first boot —
   no manual migrate step.
2. **SPA** — New → Blueprint → connect the **puzler-vue** repo. Its `render.yaml`
   provisions `puzler-web` (static site). Apply.
3. Set the env vars each Blueprint left blank (`sync: false`):
   - **puzler-api** `RAILS_MASTER_KEY` → contents of `config/credentials/production.key`
   - **puzler-api** `FRONTEND_URL` → `https://puzler.app` (can use the temporary
     `https://puzler-web.onrender.com` until DNS is set)
   - **puzler-api** `API_URL` → `https://api.puzler.app` (or `https://puzler-api.onrender.com`)
   - **puzler-web** `VITE_API_URL` → the API URL above. *This is build-time —
     after changing it, trigger a redeploy so Vite re-inlines it.*

## Part B — Custom domains

1. **API**: `puzler-api` → Settings → Custom Domains → add `api.puzler.app`.
   Render shows a CNAME target; add it at your DNS provider.
2. **SPA**: `puzler-web` → Settings → Custom Domains → add `puzler.app`
   (and `www` if you want). Add the CNAME/ALIAS Render shows.
3. Both get automatic TLS from Render. Once DNS resolves, set the final
   `FRONTEND_URL`, `API_URL`, and `VITE_API_URL` to the custom domains and
   redeploy both services.

This drives **CORS** (`config/initializers/cors.rb`), **ActionCable** allowed
origins, **OAuth** redirect targets, and **password-reset email links** — all
already parameterized off those env vars.

Confirm the API: `https://api.puzler.app/up` → 200, `/` → hello JSON,
`/explorer` loads.

## Part C — OAuth production redirect URIs

The OAuth providers must whitelist the production callback URLs:

- **Google Cloud Console** → your OAuth client → add Authorized redirect URI
  `https://api.puzler.app/users/auth/google_oauth2/callback` and JS origin
  `https://puzler.app`. Publish the consent screen (move out of "testing") so
  non-test users can sign in.
- **Patreon** → your client → add redirect URI
  `https://api.puzler.app/users/auth/patreon/callback`.

You can reuse the existing OAuth apps for both dev and prod (just add the new
URIs), or create separate production clients. Either way, put the client
ID/secret you want production to use into the production credentials (Part D).

## Part D — Fill production credentials

The production credentials file currently has real internal secrets but
`PLACEHOLDER_REPLACE_ME` for vendor keys. Fill them:

```bash
cd api
bin/rails credentials:edit --environment production
```

Replace placeholders for: `sendgrid.api_key`, `google.client_id/secret`,
`patreon.client_id/secret`, and `r2.account_id/access_key_id/secret_access_key`
(bucket is preset to `puzler`). Commit the re-encrypted `production.yml.enc`
(safe — it's encrypted; the key is not in the repo).

The app boots fine with placeholders still present — those features (email,
OAuth, avatar uploads) just won't work until the real keys are in. So you can
launch the core app first and fill these in as you go.

Also create the mailboxes referenced in the legal docs before public launch:
`privacy@puzler.app` and `support@puzler.app` (a forward to your inbox is fine).

## Part E — Smoke test (production)

- [ ] `GET https://api.puzler.app/up` → 200; `/` → hello JSON; `/explorer` loads
- [ ] Email signup → login → logout on the live SPA
- [ ] Google + Patreon sign-in (after Parts C & D)
- [ ] Forgot password → email arrives via SendGrid → reset link lands on the SPA
- [ ] Avatar upload (verifies R2)
- [ ] Open a puzzle that uses live updates → ActionCable connects (no WS origin errors in console)
- [ ] Footer links resolve; legal pages deep-link on hard refresh
- [ ] `Settings → Your Data` → download works; delete-account on a throwaway account

---

## Notes

- **Redeploys**: push to `main`; Render auto-deploys both the API and the static
  site. Migrations run automatically on the API via the Docker entrypoint.
- **Secrets are env vars or encrypted credentials** — never commit `production.key`
  (it's gitignored) or set secrets in `render.yaml`.
- **Sidekiq later**: the Redis instance is `noeviction` and shared-ready; add the
  `sidekiq` gem, a worker service in `render.yaml`, and point Active Job at it.
- **Optional hardening** (not required to launch): `config.hosts` allow-list
  (DNS-rebinding protection), rate limiting (rack-attack), email-change
  confirmation. Left out to keep the first deploy simple.
