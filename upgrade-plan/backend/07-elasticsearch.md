# 07 — Elasticsearch client upgrade

| | |
|---|---|
| **Estimate** | 0.5–1 week |
| **Depends on** | [01 — Gem audit](./01-gem-audit.md) |
| **Blocks** | Nothing — can be done independently after B0 |

[← Back to overview](./README.md)

---

## Goal

Align the Ruby `elasticsearch` client gem with the production server version. No server infrastructure change is needed.

---

## Current state (confirmed via production SSH — June 2026)

| Component | Version |
|-----------|---------|
| **ES server** | **7.17.24** (Elasticsearch 7 LTS, latest patch) |
| **ES server host** | `192.168.176.65:9200` (private network from web node) |
| **ES server cluster** | `ProtectedPlanet` |
| **Ruby client gem** | `elasticsearch ~> 7.2.0` |
| **Lucene** | 8.11.3 |

---

## What to do

### Step 1 — Bump the Ruby client to `~> 7.17`

The `elasticsearch` 7.x client is backwards-compatible within the 7.x series. Bumping from 7.2.0 to 7.17 brings security patches and aligns the client with the server version. No API changes are required.

```ruby
# Gemfile
gem 'elasticsearch', '~> 7.17'
```

- [ ] Update gem; `bundle update elasticsearch`
- [ ] Boot app; run search tests
- [ ] Verify `Elasticsearch::Client.new(url: ENV['ELASTIC_SEARCH_URL'])` connects successfully

### Step 2 — Verify the ENV var is wired in all environments

The production `.env` sets:
```
ELASTIC_SEARCH_URL=http://192.168.176.65:9200
```

- [ ] Confirm staging `.env` has the correct staging ES URL (may be a different node)
- [ ] Confirm development `.env` / Docker config points to the local ES container
- [ ] Confirm `config/initializers/` — check how `ELASTIC_SEARCH_URL` is consumed and passed to the client

### Step 3 — Smoke-test search

- [ ] Search returns results for a known protected area name
- [ ] Aggregation filters (country, region, IUCN category, governance) all return results
- [ ] ES index mapping has not changed (7.17 is the same schema as 7.2 — no re-index needed)

---

## ES 8.x — deferred

Upgrading to ES 8 is a **separate initiative** from the Rails upgrade. ES 8 has breaking changes that require infrastructure involvement:

- Security enabled by default (TLS + auth) — production infrastructure change
- `_type` removed from all APIs
- Some aggregation field names changed
- Client gem major version bump (`elasticsearch` 8.x or switch to `elastic-enterprise-search`)

This should be scoped and planned independently, after the Rails 8 upgrade is stable. The server running 7.17.24 is fully supported and receives security patches — no urgency.

---

## Index management reference

Elasticsearch indices are defined in `lib/modules/search/`. Key files to be aware of (for future ES 8 work, not this phase):

- Index definition / mappings
- Search query builders
- Aggregation logic (`config/search.yml` drives filter types)

---

## Exit criteria

- `elasticsearch` gem on `~> 7.17`
- App connects to production ES (7.17.24) without warnings
- All search and aggregation tests pass
- No ES 8 changes attempted in this phase
