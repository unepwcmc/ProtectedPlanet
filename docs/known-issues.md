# Known Issues

Open items needing a decision, an environment, or a fix. Remove an entry when it
is closed.

Last verified against the code: **2026-09-02**.

## 🔴 Search is broken in every environment

`AppSecrets.elasticsearch` is a plain `Hash`, but two call sites reach into it
with dot access:

- `lib/modules/search.rb:130`
- `lib/modules/search/index.rb:71`

```ruby
Elasticsearch::Client.new(url: AppSecrets.elasticsearch.url)
#                                                      ^^^^ NoMethodError
```

`config_for` returns an `OrderedOptions` at the top level only — nested hashes
stay plain, as `config/initializers/00_app_secrets.rb` says in its own comment
("nested hashes intact… `AppSecrets.redis[:url]`"). So this is not
test-environment drift: it fails identically in development, staging and
production.

**Verified 2026-09-02:** `GET /search?search_term=peru` returns **HTTP 500** in
the dev container, logging `undefined method 'url' for an instance of Hash`, and
`AppSecrets.elasticsearch.respond_to?(:url)` is `false` under `RAILS_ENV=development`.

**Fix** — use `[:url]` at both call sites. Confirmed working: with
`AppSecrets.elasticsearch[:url]` the client builds and `client.ping` returns
`true` against the local ES container.

This is also the sole cause of the failing test suite (below), so the two close
together.

## CI

- **The Ruby suite is red: 730 runs, 0 failures, 41 errors, 0 skips**
  (full run, 2026-09-02).
  - **40 of the 41 are the search bug above**, across six files:
    `test/integration/search_test.rb` (18), `test/unit/search_test.rb` (6),
    `test/integration/search_areas_test.rb` (6),
    `test/integration/search_page_test.rb` (5),
    `test/unit/search/index_test.rb` (4), `test/unit/autocompletion_test.rb` (1).
    Most enter through `test_helper.rb:98` (`fresh_search_index`). Fixing the two
    call sites should clear all 40.
  - **1 is `release_orchestration_integration_test.rb`** — *"Target staging table
    `staging_protected_areas` does not exist or has no records"*. Treat as
    unconfirmed: it surfaced in a run made after a concurrent suite was killed
    mid-flight, and this test shares staging tables with anything else touching
    the test database. **Re-run it alone** before believing it:
    `bin/rails test test/integration/wdpa/portal/release_orchestration_integration_test.rb`
- **The explanation at the top of `.github/workflows/test.yml` is out of date.**
  It blames `lib/tasks/db.rake` seeding 248 countries and colliding on
  `countries_pkey`. That file was deleted in the cleanup, and the current run
  shows **zero** such failures. Replace that paragraph when the suite is fixed.
- **Not a required check.** Deliberate while the suite is red — add the jobs to
  branch protection once it is green.
- **Snyk has no successor.** It was a Jenkins plugin step and stopped scanning
  when Jenkins was retired. Porting it means a `snyk/actions` step plus a
  `SNYK_TOKEN` secret. Open decision.
- **Nothing runs `rubocop` in CI.** The gem is in the `development` group and
  `.rubocop.yml` exists, but no workflow invokes it. Open decision.

## Deploy

- **No Kamal production destination.** `config/deploy.yml` and
  `config/deploy.staging.yml` both set `RAILS_ENV: staging`. There is no working
  production deploy path until one is added.

## Release

- **The portal checkpoint file store has no owner, and nothing resets it.** With
  no `Release` to hang off, `Wdpa::Portal::Checkpoint` persists offsets to
  `tmp/portal_checkpoints.json`, which survives across runs. A dry run or a
  crashed release leaves stale offsets behind and **the next real release
  silently imports zero records** — the visible symptom is *"Target staging table
  `staging_protected_areas` does not exist or has no records"*.
  It logs a loud warning when it takes that branch (`checkpoint.rb:23-27`), but
  that is the only guard. ⚠️ **Correction to the audit record:** it claimed
  `Checkpoint.reset_all!` was added to the setup and teardown of both portal
  integration tests. It is not there — `grep -rn "reset_all!" test/` matches only
  an assertion string in `adapters/protected_areas_test.rb`. So *nothing* resets
  the store, tests included. Either restore those resets, make the fallback refuse
  a store that does not belong to the current release, or disable it outside a
  `Release`.
- **`pp:portal:cleanup_backups` has not been run on the real environments.** Old
  `bkYYMMDDHHMM_*` backup tables accumulate after every release swap. The task
  takes a keep-count: `rake pp:portal:cleanup_backups[2]`.

## Data

- **`ProtectedArea#is_dopa` is written by nothing.** Its only writer,
  `Wdpa::DopaImporter`, was already broken (its `DOPA_LIST` CSV did not exist)
  and has been removed. The column survives on both `protected_areas` and
  `protected_area_parcels`, and `protected_area_presenter.rb:180` still reads it
  to decide whether to show the DOPA Explorer link — so that link is driven by
  stale data.

## Closed since the audit

- ~~Leaking `tmp_downloads_*` views~~ — now swept by
  `Download::Generators::Base.clean_tmp_download_views`, called from
  `Download::Utils` and the portal release cleanup. Zero leaked views in the dev
  database.
- ~~Dead mail scaffolding~~ — removed 2026-09-02: `ApplicationMailer`, the
  `layouts/mailer` template and every `smtp_settings` / `action_mailer` block are
  gone, with no references left. **`mailpit` is still a service in
  `docker-compose.yml`** and now has nothing to catch — drop it too, or keep it
  deliberately for when mail is built.
