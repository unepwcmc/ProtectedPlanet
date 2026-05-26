# 15 — Docker: Webpacker dev → Vite dev

| | |
|---|---|
| **Estimate** | **0.5–1 wk (~0.125–0.25 mo)** — part of [2a](./02a-vite-spike-rails-5.md) / prep |
| **Depends on** | [02a spike](./02a-vite-spike-rails-5.md) (Vite builds in Docker) |
| **Full cutover** | Remove `webpacker` service when Webpacker gem removed ([03](./03-end-runtime-compilation.md)) |

[← Summary](./README.md)

---

## Goal

Local Docker development uses **Vite** for frontend assets instead of a dedicated **webpack-dev-server** container — matching production direction and [02b](./02-vite-on-rails-8.md).

**Today:** `docker compose up` starts `protectedplanet-webpacker` on **3035**; `web` sets `WEBPACKER_DEV_SERVER_HOST=webpacker`.

**Target:** `protectedplanet-vite` on **3036**; Rails loads Vite assets (HMR when needed). Webpacker container **removed** only after Vue 2 pack is gone.

---

## Phases (do not skip straight to “webpacker gone”)

```text
D1 — Dual (Rails 5.2 now)     webpacker :3035  +  vite :3036
D2 — Vite primary (2b+)       vite :3036        +  webpacker until Vue 3 cutover
D3 — Vite only (phase 3+)     remove webpacker service + env
```

| Phase | Webpacker container | Vite container | Who serves Vue 2 `#v-app` |
|-------|---------------------|----------------|---------------------------|
| **D1** | Keep | **Add** | Still Webpacker |
| **D2** | Keep (temporary) | Primary for new entrypoints | Webpacker until islands done |
| **D3** | **Remove** | Only JS dev server | Vite only |

---

## D1 — Add Vite service (minimal change)

### 1. `docker/scripts/vite`

```bash
#!/bin/bash
set -e
cd /ProtectedPlanet
yarn install --frozen-lockfile --check-files
bundle check || bundle install
exec bin/vite dev --host 0.0.0.0 --port 3036
```

(`chmod +x`)

### 2. `docker-compose.yml` — new service

| Setting | Value |
|---------|--------|
| `container_name` | `protectedplanet-vite` |
| `ports` | `3036:3036` |
| `command` | `/ProtectedPlanet/docker/scripts/vite` |
| `volumes` | Same as `webpacker` (app + `node_modules` + bundler) |

### 3. `config/vite.json` (development)

```json
"development": {
  "autoBuild": true,
  "host": "0.0.0.0",
  "port": 3036,
  "publicOutputDir": "vite-dev"
}
```

- Keep `skipProxy: true` initially if `vite build` + static files from `public/vite-dev` are enough (current spike).
- For **HMR** on Vite entrypoints: set `skipProxy: false` and wire proxy (see D1b).

### 4. `web` service

| Change | |
|--------|--|
| `depends_on` | Add `vite` (keep `webpacker` for now) |
| Optional env | `VITE_RUBY_HOST=vite` (if using dev-server proxy) |

Do **not** remove `WEBPACKER_DEV_SERVER_HOST` until D3.

### 5. `docs/docker.md`

- List `protectedplanet-vite` in services.
- Document: **Vue 2 UI** still needs `webpacker` until cutover; **Vite spike / new entrypoints** use port **3036**.

### D1b — HMR (optional in D1)

If `vite_client_tag` should hot-reload in the browser:

- [ ] `skipProxy: false` in `config/vite.json`
- [ ] `web` env: `VITE_RUBY_HOST=vite` (vite_ruby 1.x)
- [ ] Ensure `vite` service exposes `3036` and Vite allows host `localhost` / `host.docker.internal`
- [ ] Confirm CSP in `config/initializers/content_security_policy.rb` (commented templates in [02](./02-vite-on-rails-8.md))

Without HMR, developers run `docker exec … bundle exec vite build` after JS changes (slower but simpler).

---

## D2 — After Rails 7 / Vite 5 ([02b](./02-vite-on-rails-8.md))

| Task | |
|------|--|
| [ ] Bump Node in `Dockerfile` to **20+** |
| [ ] `vite` service uses Vite 5 + `bin/vite dev` from vite_rails 3.x |
| [ ] `Procfile.dev` pattern: `web` + `vite` (document for non-Docker devs) |
| [ ] Webpacker container still runs for any remaining Vue 2 paths |

---

## D3 — Remove Webpacker from Docker ([03](./03-end-runtime-compilation.md))

| Task | |
|------|--|
| [ ] Delete `webpacker` service from `docker-compose.yml` |
| [ ] Remove `WEBPACKER_DEV_SERVER_HOST` from `web` |
| [ ] Remove `docker/scripts/webpacker` (or archive) |
| [ ] Update `docs/docker.md`, `docs/workflow.md`, `.env` examples |
| [ ] `docker compose up` default stack: web, vite, db, redis, elasticsearch, sidekiq |

---

## Developer commands (target)

```bash
# Full stack (dual period)
docker compose up

# Vite logs only
docker logs -f protectedplanet-vite

# One-off build (no HMR)
docker exec protectedplanet-web bash -lc 'cd /ProtectedPlanet && bundle exec vite build'
```

---

## Risks

| Risk | Mitigation |
|------|------------|
| Two JS servers (D1–D2) | Document which URLs use which bundler ([01-live-inventory](./01-live-inventory.md)) |
| Node 12 vs Vite 5 | D1 on Vite 2.9 only; Node 20 in D2 |
| Browser cannot reach `vite:3036` | Publish port; `host: 0.0.0.0`; test `vite_client_tag` |
| Forgetting Webpacker still required | README in `docs/docker.md` until D3 |

---

## Exit criteria

**D1**

- [ ] `docker compose up` starts `protectedplanet-vite` without errors.
- [ ] Vite entrypoints load on http://localhost:3000 (with Webpacker still running for Vue 2).

**D3**

- [ ] No `webpacker` service; `docker compose up` works for full dev on Vite only.
