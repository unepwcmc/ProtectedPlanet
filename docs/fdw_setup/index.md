# PP ↔ Data Management Portal FDW

The Protected Planet database reads Portal tables (protected areas,
effectiveness, green list) directly over **PostgreSQL Foreign Data Wrappers**.
The release importers read materialized views built on top of those foreign
tables — the view definitions are in [`FDW_VIEWS.sql`](../../FDW_VIEWS.sql).

New to the Portal? Read the
[Protected Planet WIKI](https://github.com/unepwcmc/protected-planet-wiki) and
the [release process](../release/release_process.md).

## Setup

- [Local development](local.md) — macOS + Docker Desktop
- [Production](prod.md)
