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

[Ansible](servers.md) handles installing Memcached on production.
Should you wish to set it up locally, take a look at the [Ansible
memcached scripts](../config/deploy/ansible/roles/memcached/tasks/main.yml).

## Clearing the cache

In the Rails console:

```
Rails.cache.clear
```
