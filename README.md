# Protected Planet

[protectedplanet.net](https://protectedplanet.net) — the public site for the World
Database on Protected Areas (WDPA) and WD-OECM.

Rails 8 / Ruby 3.3 · PostgreSQL + PostGIS · Elasticsearch · Sidekiq · Vue 3 +
Vite + Tailwind v4 · Comfortable Media Surfer (CMS) · deployed with Kamal.

> **New here?** Read the [Protected Planet WIKI](https://github.com/unepwcmc/protected-planet-wiki)
> first — it explains the PP family of apps and how they fit together.
>
> **VS Code users:** open
> [protected-planet-family-apps.code-workspace](protected-planet-family-apps.code-workspace)
> to get every PP app in one workspace.

## Clone

This repo has submodules (`db` is [protectedplanet-db](https://github.com/unepwcmc/protectedplanet-db)):

```bash
git clone --recurse-submodules git@github.com:unepwcmc/ProtectedPlanet.git
# already cloned?
git submodule update --init --recursive
```

## Documentation

**Getting started**
1. [Local setup with Docker](docs/docker.md) — the only supported setup path
2. [Development workflow, conventions and tips](docs/workflow.md)
3. [Deployment](docs/deployment.md)
4. [Known issues](docs/known-issues.md)

**Monthly data release**
5. [Release process](docs/release/release_process.md) — start here; CSVs and git workflow
6. [Portal release runbook](docs/release/portal_release_runbook.md) — the commands to run
7. [Release data imports](docs/release/release_data_imports.md) — what gets imported
8. [Release orchestration](docs/release/release_orchestration.md) — code-level reference
9. [FDW setup](docs/fdw_setup/index.md) — the PP ↔ Data Management Portal DB link
10. [Stats server DB ingestion](docs/stats_server_db_ingestion.md) — the `stats` schema spec

**Features**
11. [Search](docs/search.md)
12. [Downloads](docs/downloads.md)
13. [Background workers](docs/workers.md)
14. [Caching](docs/caching.md)
15. [CMS](docs/cms.md)
16. [Banner system](docs/banner_system.md)
17. [Protected areas and parcels](docs/protected_area_parcels.md)
18. [Green List](docs/green_list.md)

**Reference**
19. [Shared Chrome for PDF rendering](docs/pdf-shared-chrome.md)
20. [GDAL: FileGDB SDK → OpenFileGDB](docs/GDAL-openfilegdb-migration.md)
21. [`upgrade-plan/`](upgrade-plan/) — historical record of the Rails 5→8 and
    Webpacker→Vite upgrades

## Licence

[BSD 3-Clause](http://opensource.org/licenses/BSD-3-Clause).
