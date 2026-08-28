# Caching

> ## ⚠️ **WARNING**
>
> This file is left here for reference. Explicit caching has been removed,
> As of 25Nov2025 - Consider removing Memcached and implementing a simpler solution with fewer dependencies.

## How does it work?

The pages are cached via
[Rack::Cache](http://rtomayko.github.io/rack-cache/) and Memcached.
Rack::Cache sits inbetween nginx and Rails as a Rack middleware, and
stores the requested pages in memcached and serves them directly on
request, completely avoiding the Rails stack.

In production Memcached runs as a service on the deploy host, not in a container —
the app reaches it at `host.docker.internal:11211` (`MEMCACHE_SERVERS` in
`config/deploy.yml`). Locally it is the `memcached` container in `docker-compose.yml`.

## Clearing the cache

In the Rails console:

```
Rails.cache.clear
```
