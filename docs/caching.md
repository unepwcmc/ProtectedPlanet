# Caching

As the import process drops the database and replaces it, Protected
Planet is an almost entirely static site. One of the many advantages of
this is that we can aggressively cache most of the pages.

## What is cached?

In production only, the home page and all Protected Area show pages are cached for 30 days
on first visit.

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
