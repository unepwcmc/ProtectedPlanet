# Deployment

Deployment is **automatic via GitHub Actions**, one workflow per destination:

| Push to | Workflow | Kamal destination | Host |
|---|---|---|---|
| `staging_kamal` | [`deploy-staging-kamal.yml`](../.github/workflows/deploy-staging-kamal.yml) | `staging` | `pp-web-staging-01` |
| `production_kamal` | [`deploy-production-kamal.yml`](../.github/workflows/deploy-production-kamal.yml) | `production` | `pp-web-prod-01` |

Both build from `Dockerfile.deploy`, deploy with [Kamal 2](https://kamal-deploy.org)
on a self-hosted runner, and report start, success and failure to Slack. Either
can also be started by hand with **Run workflow** (`workflow_dispatch`).

There is nothing to run locally. A manual `kamal deploy -d <destination>` works if
you have the host access and secrets, but it bypasses the Slack notifications and
the secret validation step — use the workflow.

## Configuration

| What | Where |
|---|---|
| Shared Kamal config (registry, builder, accessories) | `config/deploy.yml` |
| Per-destination: hosts, roles, env | `config/deploy.staging.yml`, `config/deploy.production.yml` |
| Secret names (values from the GitHub environment) | `.kamal/secrets-common` |
| Migrations, run pre-deploy | `.kamal/hooks/pre-deploy` |
| Image build | `Dockerfile.deploy` |

Secrets live in the `staging_proxmox` / `production_proxmox` GitHub environments.
Each workflow passes only the ones `.kamal/secrets-common` actually references —
don't widen that list to the whole `secrets` context.

`config/deploy.yml` pins the **staging** host for the builder and the
Elasticsearch accessory, so `deploy.production.yml` restates both in full. Kamal
merges accessories by name, and a missed `host` would deploy Elasticsearch onto
the staging box.

## Topology

Each destination is a single Proxmox VM running two roles:

- **`web`** — Puma behind kamal-proxy (TLS from an explicit certificate, not
  ACME; 120s response timeout for the slow country and PDF endpoints).
- **`job_default`** — Sidekiq, with `init: true` so tini reaps the PDF Chrome's
  orphaned children, and `RAILS_MAX_THREADS: 25` to match its 25 Sidekiq threads.

Elasticsearch is a Kamal accessory. Redis and Memcached are bound on the host and
reached through `host.docker.internal`.

Hostnames, IPs and credentials are in the Kamal configs and Keeper — not here.

## Useful commands

Run these against a destination, from a checkout with host access:

```bash
kamal app logs -d production --roles=web -f
kamal app exec -d production --reuse -i "bash"
kamal app exec -d production --reuse "bin/rails console"
```
