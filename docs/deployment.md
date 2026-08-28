<!-- TODO: update the readme now it uses Github action + Kamal -->
# Deployment

## Kamal

Deployments are handled by Kamal, from `config/deploy.yml` and
`config/deploy.staging.yml`:

```
kamal deploy -d staging
```

Capistrano was removed in Aug 2026. At the time of removal only staging had a
Kamal destination; a production one still needs adding before production can be
deployed.

## Initial Machine Setup

Servers are provisioned by Kamal from `config/deploy.yml` / `config/deploy.staging.yml`
and the images built by `Dockerfile.deploy`.

It had not been touched since 2019, and its inventories named bare-metal hosts
(`www-prod.protectedplanet.net`, `db-prod.protectedplanet.net`, an EC2 box) that were
decommissioned two migrations ago — first to Docker, then to Kamal.

> **Its two `ansible-vault` files (`group_vars/all`, `group_vars/db`) held production
> secrets.** Deleting them does not invalidate anything, and the ciphertext remains in
> git history. If any of those values was ever reused elsewhere, have it rotated.

## Maintenance Mode

Servers can be put in to maintenance mode to restrict access to the
site during deploys, maintenance, etc. This state is handled by the
`AdminController`, and is secured by a `maintenance_mode_key` in in the
`secrets.yml` config file.

### Manually

If you need to turn on maintenance mode from a different server, as the
Utility box has to do during an import, you can do so via HTTP:

```
# On
curl -X PUT -d maintenance_mode_on=true --header "X-Auth-Key: <key>" <domain>/admin/maintenance
# Off
curl -X PUT -d maintenance_mode_on=false --header "X-Auth-Key: <key>" <domain>/admin/maintenance
```

