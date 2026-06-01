# 11 — Deploy & DevOps (B2, B5)

| | |
|---|---|
| **Estimate** | 1–2 weeks · ~0.25–0.5 month |
| **Depends on** | [04 — Rails 7.1 (B0)](./04-rails-7.md) · [02 — Ruby upgrade](./02-ruby-upgrade.md) |
| **Blocks** | **B2** (staging deploy with `vite build`) · **B5** (Webpacker removed from deploy) |

[← Back to overview](./README.md)

---

## Goal

Production and staging deploy updated for the new stack: Ruby 3.x, Node 20, Capistrano updated, Webpacker removed, `bin/vite build` wired in. Both B2 and B5 are shared milestones with the frontend team.

---

## Current deployment state

| Item | Current |
|------|---------|
| Tool | Capistrano 3.11.0 |
| Branches | `develop` → staging · `master` → production |
| Ruby on server | 2.6.3 (via rvm) |
| Node on server | v10.15.1 (set in `deploy.rb`) |
| App server | Passenger (via `capistrano-passenger`) |
| Webpacker | Runs at deploy via `assets:precompile` |
| Sidekiq | Two processes: `pp_default`, `pp_import` (restarted via `service:` tasks) |
| Git submodule | DB submodule via `capistrano-git-with-submodules` |

---

## Step 1 — Ruby version on servers

At each Ruby bump, update Capistrano config and the actual server Ruby:

- [ ] Update `set :rvm_ruby_version, '2.7.8'` in `config/deploy.rb` (for B0)
- [ ] Update to `3.3.x` after Ruby 3 upgrade — [02](./02-ruby-upgrade.md)
- [ ] Confirm rvm has the new Ruby installed on the staging server before deploying:
  ```bash
  ssh wcmc@new-web.pp-production.linode.protectedplanet.net 'rvm list'
  ```
- [ ] Install if missing: `rvm install 3.3.x`
- [ ] Ansible role for Ruby (if any in `config/deploy/ansible/`) — update the version pin there too

---

## Step 2 — Node 20 on servers (required for B2)

The staging and production servers currently run Node v10.15.1. Vite 5 and modern npm packages require **Node 20 LTS** minimum.

```ruby
# config/deploy.rb — update before B2
set :nvm_node, 'v20.x.x'   # use latest Node 20 LTS
```

- [ ] Check if `nvm` is installed on the server: `ssh wcmc@... 'nvm --version'`
- [ ] Install Node 20 via nvm: `nvm install 20 && nvm alias default 20`
- [ ] Update Ansible role that sets Node version (check `config/deploy/ansible/`)
- [ ] Update Docker dev Node version — see [frontend/15](../frontend/15-docker-vite-dev.md) (Docker is frontend-owned but may reference Node version from here)
- [ ] Confirm `yarn` or `npm` version compatible with Node 20

---

## Step 3 — Capistrano upgrade

Capistrano 3.11.0 was released in 2018 and has Ruby 3 compat issues (string frozen literal, deprecated Net::SSH patterns).

- [ ] Upgrade to `capistrano '~> 3.18'` (or latest 3.x)
- [ ] Update `capistrano-rails`, `capistrano-bundler`, `capistrano-passenger` in lockstep
- [ ] Update `capistrano-sidekiq` to match Sidekiq 7 — see [08](./08-sidekiq-and-workers.md)
- [ ] Update `capistrano-rvm` or switch to system Ruby if rvm is being phased out on the server
- [ ] Test a dry-run deploy to staging: `cap staging deploy --dry-run`
- [ ] Verify `set :linked_files` and `set :linked_dirs` still resolve correctly

---

## Step 4 — Vite build in deploy (B2)

Once B0 is done and the frontend team has Vite 5 running on the upgrade branch, wire `bin/vite build` into the Capistrano deploy.

**B2 is satisfied when:** staging deploy runs `bin/vite build` and the built assets are served correctly.

```ruby
# In config/deploy.rb or a deploy task
namespace :deploy do
  after :updated, 'deploy:vite_build'
  
  task :vite_build do
    on roles(:web) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, 'exec vite build'
        end
      end
    end
  end
end
```

- [ ] Confirm `NODE_ENV=production` is set during build
- [ ] Confirm `VITE_*` environment variables are available at build time (Mapbox token, etc.)
- [ ] Confirm built manifest at `public/vite/manifest.json` is included in the release
- [ ] Test rollback: `cap staging deploy:rollback` — confirm previous asset manifest is restored
- [ ] Document the dual-compile period (Webpacker + Vite) in deploy notes — both must run until B5

---

## Step 5 — Webpacker removal (B5)

B5 is shared with the frontend team. Do not remove Webpacker from the deploy until the frontend has completed its Vite cutover.

- [ ] Coordinate with frontend: confirm Webpacker JS pack tags are all removed from ERB
- [ ] Remove `gem 'webpacker'` from Gemfile
- [ ] Remove `javascript_pack_tag` / `stylesheet_pack_tag` from deploy hooks (if any explicit calls)
- [ ] Remove `webpacker` from `config/deploy.rb` `assets:precompile` hooks if explicitly added
- [ ] Remove Webpacker-related env vars from `.env` if any
- [ ] Confirm `config/webpacker.yml` is deleted (or archived)
- [ ] Deploy to staging — confirm no Webpacker-related errors
- [ ] Tag B5

---

## Passenger

The production app server is Passenger (via `capistrano-passenger`). Puma config is present but Passenger is in use on the server.

- [ ] Confirm Passenger version on the production server: `ssh wcmc@... 'passenger --version'`
- [ ] Confirm Passenger supports Rails 8 + Ruby 3.x (Passenger 6.0.x supports both)
- [ ] If Passenger upgrade needed: coordinate with server admin (requires nginx/Apache reload)
- [ ] No plan to switch from Passenger to Puma in this upgrade — Puma config exists but is not active

---

## AppSignal

- [ ] Upgrade `appsignal` to `~> 4.x` before Rails 8 (3.x has no Rails 8 support)
- [ ] Confirm AppSignal agent key is set in `.env` on both servers
- [ ] After Rails 8 deploy, confirm AppSignal dashboard shows the new app version

---

## Environment variables reference

Variables that must be present on servers (cross-reference `.env`):

| Variable | Purpose | Updated in this phase? |
|----------|---------|----------------------|
| `ELASTIC_SEARCH_URL` | ES client connection | No — already `http://192.168.176.65:9200` |
| `POSTGRES_HOST` / `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DBNAME` | DB | No |
| `REDIS_URL` (or default localhost) | Sidekiq | No |
| `NODE_ENV` | Vite build | **Add: `production` for deploy** |
| `VITE_*` | Frontend env vars at build time | **Coordinate with frontend** |
| `RAILS_MASTER_KEY` | Credentials decryption (after secrets.yml migration) | **Add after [04](./04-rails-7.md)** |

---

## Exit criteria

- Ruby 3.3.x deployed to staging via Capistrano without errors
- Node 20 on staging server; `bin/vite build` runs in deploy (B2 ✓)
- Capistrano 3.18+ with updated companion gems
- Webpacker removed from Gemfile and deploy pipeline (B5 ✓)
- Passenger confirmed compatible with Rails 8 + Ruby 3.3
- AppSignal upgraded to 4.x and reporting on Rails 8
- Deploy runbook updated with new steps (`vite build`, Ruby version, Node version)
