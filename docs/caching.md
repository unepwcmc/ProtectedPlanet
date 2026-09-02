# Caching

> ⚠️ Explicit page caching was removed in Nov 2025. This describes what is still
> wired up. Worth revisiting whether Memcached earns its dependency.

`config.cache_store = :mem_cache_store` (dalli-backed) in staging and production,
pointed at `memcache_servers` from `config/app_secrets.yml`, with a 10MB value
ceiling. `rack-cache` is still in the `production, staging` bundle group.

On the deployed hosts Memcached runs as a host service, not a container — the app
reaches it at `host.docker.internal:11211` (`MEMCACHE_SERVERS` in
`config/deploy.yml`). Locally it is the `memcached` container.

Clear it from the Rails console with `Rails.cache.clear`, or over HTTP via
`PUT /admin/clear_cache`.
