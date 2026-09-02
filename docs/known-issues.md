# Known Issues

Open items carried over from the 2026 dead-code audit (all seven cleanup waves
were actioned; these are the ones needing a decision or an environment, not an
edit). Remove an entry when it is closed.

## Security

- **Live secrets remain in git history.** The `.travis.yml` encrypted tokens and
  the two `config/deploy/ansible/group_vars` `ansible-vault` files were deleted,
  but deletion does not invalidate them and the ciphertext is still in history.
  **Have those values rotated.** Highest-value item here.

## Deploy

- **No Kamal production destination.** `config/deploy.yml` and
  `config/deploy.staging.yml` both target staging (`RAILS_ENV: staging`). There
  is no working production deploy path until one is added.

## Release

- **The portal checkpoint file store has no owner.** With no `Release` to hang
  off, `Wdpa::Portal::Checkpoint` persists offsets to `tmp/portal_checkpoints.json`,
  which survives across runs. A dry run or a crashed release leaves stale offsets
  behind and **the next real release silently imports zero records**. Only the
  portal integration tests reset it. The fallback should refuse a store that does
  not belong to the current release, or be disabled outside a `Release`.
- **Database housekeeping** — `pp:portal:cleanup_backups` has not been run on the
  real environments, and the leaking `tmp_downloads_*` views need filing as a bug.

## Data

- **`ProtectedArea#is_dopa` is written by nothing.** Its only writer,
  `Wdpa::DopaImporter`, was already broken (its `DOPA_LIST` CSV did not exist) and
  has been removed. `protected_area_presenter.rb:180` still reads the flag for the
  DOPA Explorer link, so that link is driven by stale data.

## CI

- **The Ruby suite is not a required check.** `.github/workflows/test.yml` runs it
  but is deliberately excluded from branch protection while it is red. Add it once
  it is green — see the comment at the top of that file.
- **Snyk has no successor.** It was a Jenkins plugin step and stopped scanning when
  Jenkins was retired. Porting it means a `snyk/actions` step plus a `SNYK_TOKEN`
  secret. Open decision.
- **Nothing runs `rubocop` in CI.** Open decision.

## Product

- **Mail scaffolding is dead but configured.** `ApplicationMailer` has no
  subclasses and nothing calls `deliver_now`/`deliver_later`, yet three
  environments carry real `smtp_settings` and `docker-compose.yml` runs `mailpit`.
  Delete-or-build is a product question.
