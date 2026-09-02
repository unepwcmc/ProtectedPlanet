# Deployment

Deployment is **automatic via GitHub Actions**. Pushing to `staging_kamal` runs
[`deploy-staging-kamal.yml`](../.github/workflows/deploy-staging-kamal.yml),
which builds the image from `Dockerfile.deploy`, deploys it with
[Kamal 2](https://kamal-deploy.org) on a self-hosted runner, and reports start,
success and failure to Slack. It can also be started by hand with
**Run workflow** (`workflow_dispatch`).

There is nothing to run locally. A manual `kamal deploy -d staging` works if you
have the host access and secrets, but it bypasses the Slack notifications and
the secret validation step — use the workflow.

## Configuration

| What | Where |
|---|---|
| Shared Kamal config | `config/deploy.yml` |
| Destination: hosts, roles, env | `config/deploy.staging.yml` |
| Secret names (values from the GitHub environment) | `.kamal/secrets-common` |
| Migrations, run pre-deploy | `.kamal/hooks/pre-deploy` |
| Image build | `Dockerfile.deploy` |

Secrets live in the `staging_proxmox` GitHub environment. The workflow passes
only the ones `.kamal/secrets-common` actually references — don't widen that
list to the whole `secrets` context.

## Topology

Staging runs on a single Proxmox VM. Two roles:

- **`web`** — Puma behind kamal-proxy (TLS from an explicit certificate, not
  ACME; 120s response timeout for the slow country and PDF endpoints).
- **`job_default`** — Sidekiq, with `init: true` so tini reaps the PDF Chrome's
  orphaned children.

Elasticsearch is a Kamal accessory. Redis and Memcached are bound on the host
and reached through `host.docker.internal`.

Hostnames, IPs and credentials are in the Kamal configs and Keeper — not here.

## Production

> ⚠️ **There is no production destination yet.** Both Kamal configs target
> staging. One has to be added before production can be deployed.
> See [known-issues.md](known-issues.md).

## Useful commands

Run these against the destination, from a checkout with host access:

```bash
kamal app logs -d staging --roles=web -f
kamal app exec -d staging --reuse -i "bash"
kamal app exec -d staging --reuse "bin/rails console"
```

## Maintenance mode

Handled by `AdminController`, secured by `maintenance_mode_key`:

```bash
curl -X PUT -d maintenance_mode_on=true  --header "X-Auth-Key: <key>" <domain>/admin/maintenance
curl -X PUT -d maintenance_mode_on=false --header "X-Auth-Key: <key>" <domain>/admin/maintenance
```

## History

Capistrano and the 2019 Ansible provisioning were removed in Aug 2026. The
Ansible tree's two `ansible-vault` files held production secrets — deleting them
did not invalidate anything and the ciphertext is still in git history. See
[known-issues.md](known-issues.md).
