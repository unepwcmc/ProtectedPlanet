# Stats Server DB Ingestion — DevOps Specification

**Context:** The Protected Planet website is switching from CSV-based stats ingestion to reading directly from Vincent's stats server results, which are written into the PP database. This document specifies the exact schema, tables, and access requirements needed on staging and production.

---

## 1. Databases

Apply to **both**:

| Environment | Database |
|-------------|----------|
| Staging     | PP staging PostgreSQL DB |
| Production  | PP production PostgreSQL DB |

---

## 2. Schema

Create a new schema on both DBs:

```sql
CREATE SCHEMA IF NOT EXISTS stats;
```

Vincent's stats server process needs **INSERT, UPDATE, DELETE, SELECT** on this schema (it manages its own data — truncates and re-inserts on each run).

The PP Rails application user needs **SELECT** on this schema.

---

## 3. Tables

The stats server owns and manages these three tables. The PP app reads from them. Vincent's server will create/manage them, but the schema must exist and access must be granted first.

### 3.1 `stats.national_stats`

Per-country coverage stats. Maps to the current `country_statistics` table in the PP app (minus the NR fields — see Section 4).

| Column | Type | Notes |
|--------|------|-------|
| `metadata_ns_uuid` | text | Primary identifier for a run |
| `metadata_basemap` | text | e.g. `newD` |
| `metadata_grid` | text | e.g. `1x1dd` |
| `metadata_vintage` | text | e.g. `Jun2026` — **use this to filter latest release** |
| `metadata_version` | text | e.g. `Restricted` |
| `metadata_universe` | text | e.g. `all-countries` |
| `metadata_author` | text | |
| `metadata_server` | text | |
| `metadata_run_timestamp` | timestamptz | Use to pick most recent run within a vintage |
| `iso3` | text | ISO3 country code, joins to `countries.iso_3` |
| `pa_marine` | float | |
| `pa_terrestrial` | float | |
| `oecm_marine` | float | |
| `oecm_terrestrial` | float | |
| `pa_oecm_marine` | float | |
| `pa_oecm_terrestrial` | float | |
| `total_marine` | float | |
| `total_terrestrial` | float | |
| `pa_marine_pct` | float | |
| `pa_terrestrial_pct` | float | |
| `oecm_marine_pct` | float | |
| `oecm_terrestrial_pct` | float | |
| `pa_oecm_marine_pct` | float | |
| `pa_oecm_terrestrial_pct` | float | |
| `metadata` | jsonb | Full run metadata blob |

### 3.2 `stats.global_stats`

Global aggregate stats. Maps to the current `global_statistics` table in the PP app.

| Column | Type | Notes |
|--------|------|-------|
| `metadata_gs_uuid` | text | Primary identifier for a global stats run |
| `metadata_ns_uuid` | text | Links to `national_stats` run |
| `metadata_basemap` | text | |
| `metadata_grid` | text | |
| `metadata_vintage` | text | e.g. `Jun2026` — **use to filter latest release** |
| `metadata_version` | text | |
| `metadata_universe` | text | |
| `metadata_author` | text | |
| `metadata_server` | text | |
| `metadata_run_timestamp` | timestamptz | Use to pick most recent run within a vintage |
| `stat_type` | text | Field name, e.g. `global_ocean_percentage` |
| `stat_description` | text | **Do NOT use on website** — keep description from CSV (see Section 4) |
| `stat_value` | text | Numeric value as string |
| `metadata` | jsonb | Full run metadata blob |

### 3.3 `stats.pame_stats`

Per-country PAME coverage stats. Maps to the current `pame_statistics` table.

| Column | Type | Notes |
|--------|------|-------|
| `uuid` | text | Run identifier (parsed from metadata) |
| `iso3` | text | ISO3 country code |
| `pa_marine` | float | |
| `pa_terrestrial` | float | |
| `oecm_marine` | float | |
| `oecm_terrestrial` | float | |
| `pa_oecm_marine` | float | |
| `pa_oecm_terrestrial` | float | |
| `total_marine` | float | |
| `total_terrestrial` | float | |
| `pa_marine_pct` | float | |
| `pa_terrestrial_pct` | float | |
| `oecm_marine_pct` | float | |
| `oecm_terrestrial_pct` | float | |
| `ns_pa_marine` | float | |
| `ns_pa_terrestrial` | float | |
| `ns_oecm_marine` | float | |
| `ns_oecm_terrestrial` | float | |
| `ns_pa_oecm_marine` | float | |
| `ns_pa_oecm_terrestrial` | float | |
| `pa_marine_pct_of_ns` | float | |
| `pa_terrestrial_pct_of_ns` | float | |
| `oecm_marine_pct_of_ns` | float | |
| `oecm_terrestrial_pct_of_ns` | float | |
| `pa_oecm_marine_pct_of_ns` | float | |
| `pa_oecm_terrestrial_pct_of_ns` | float | |
| `metadata` | jsonb | Full run metadata blob |

---

## 4. What Stays in CSV (Merge Fields)

These fields are **not** provided by the stats server. The PP importer will still read them from CSV and merge:

### `country_statistics` / `stats.national_stats` merge:

The following columns exist in the current `country_statistics_*.csv` but are **absent from `stats.national_stats`**:

| CSV Column | Notes |
|------------|-------|
| `percentage_nr_land_cover` | National Report — updated ~every 6 years |
| `percentage_nr_marine_cover` | National Report |
| `nr_version` | National Report |
| `nr_report_url` | National Report |

These will continue to be sourced from the CSV and merged with stats server data during the monthly release import step.

### `global_statistics` / `stats.global_stats` merge:

| CSV Column | Notes |
|------------|-------|
| `description` | Do **not** use `stat_description` from the stats server on the website. Keep using the description from `global_statistics_*.csv`. |

---

## 5. Filtering Logic (for PP Developer Reference)

The stats tables accumulate across runs. **Do not filter on `metadata_universe`** — its value is inconsistent across vintages (observed: `all-countries`, `All`, and a full comma-separated ISO3 list). Instead the PP importer selects a single run per vintage:

- **Vintage**: filter `metadata_vintage = 'Jun2026'` (the release label)
- **Run selection**: within the vintage, pick the run (`metadata_ns_uuid` / `metadata_gs_uuid` / `metadata_pame_uuid`) covering the **most rows**, tie-break latest `metadata_run_timestamp`. This naturally ignores partial/test runs (e.g. single-country runs).

Example for national stats:
```sql
-- 1. pick the run
SELECT metadata_ns_uuid
FROM stats.national_stats
WHERE metadata_vintage = 'Jun2026'
GROUP BY metadata_ns_uuid
ORDER BY COUNT(*) DESC, MAX(metadata_run_timestamp) DESC
LIMIT 1;

-- 2. fetch its rows
SELECT * FROM stats.national_stats WHERE metadata_ns_uuid = '<run id from step 1>';
```

---

## 6. Summary of Required Actions (DevOps)

1. **Create `stats` schema** on staging DB and production DB
2. **Grant WRITE access** to the stats server DB user on `stats` schema (INSERT, UPDATE, DELETE, SELECT, CREATE TABLE)
3. **Grant SELECT access** to the PP Rails app DB user on `stats` schema
4. **Verify connectivity** from Vincent's stats server (`wcmc-pp-internal-01`) to staging DB first, then production
5. Confirm with Vincent that tables will be created by his server on first run, or provide DDL from Section 3 above if pre-creation is needed

---

## 7. Relationship to Current Tables

| Current PP Table | New Stats Source | CSV Still Needed? |
|-----------------|-----------------|-------------------|
| `country_statistics` | `stats.national_stats` | Yes — for NR fields only |
| `pame_statistics` | `stats.pame_stats` | No |
| `global_statistics` | `stats.global_stats` | Yes — for `description` field only |
| `staging_country_statistics` | `stats.national_stats` | Yes — for NR fields only |
| `staging_pame_statistics` | `stats.pame_stats` | No |
| `staging_global_statistics` | `stats.global_stats` | Yes — for `description` field only |

---

## 8. App-Side Consumption (PP Importer)

The portal release importers can read stats from the `stats` schema instead of CSVs, toggled by an ENV var.

### Toggle

| Setting | Behaviour |
|---------|-----------|
| `PP_STATS_SOURCE=csv` (default) | Current behaviour — stats imported from `lib/data/seeds/*.csv` |
| `PP_STATS_SOURCE=db` | Stats read from `stats.national_stats`, `stats.pame_stats`, `stats.global_stats` |

Applies to the portal release flow only (`rake pp:portal:release`). The legacy live import flow (`Wdpa::Importer`) is unchanged and always uses CSV.

### Error handling — no silent fallback

In `db` mode, if no rows exist for the release vintage (label, e.g. `Jun2026`), the stats importers return a **hard error** and the release fails visibly. This is deliberate: silently falling back to CSV would publish stale numbers as a new release. To fall back, re-run explicitly with `PP_STATS_SOURCE=csv`.

### Run selection

As described in Section 5: biggest run within the vintage matching the release label, tie-break latest `metadata_run_timestamp`. Run id columns: `metadata_ns_uuid` (national), `metadata_pame_uuid` (PAME), `metadata_gs_uuid` (global).

### Scale conversion

`stats.national_stats` and `stats.pame_stats` store percentage columns as **fractions (0–1)**; the importer multiplies by 100 to match PP columns (0–100). `stats.global_stats` values are already 0–100 — no conversion. `NaN` values map to `NULL`.

### CSV merge in db mode

- **Country stats**: NR fields (`percentage_nr_land_cover`, `percentage_nr_marine_cover`, `nr_version`, `nr_report_url`) merged from the latest `country_statistics_*.csv` by iso3. Update NR data by committing a new CSV — no stats-server involvement.
- **Global stats**: hybrid — CSV provides the full base (including fields the stats server doesn't emit, e.g. `green_list_*`, PA counts), stats-server values overwrite where present. Unknown `stat_type` values are skipped with a soft error. `stat_description` is ignored (the `global_statistics` table has no description column).
- **PAME stats**: no CSV merge; `assessments` / `assessed_pas` still computed from PP's own PAME evaluations.

### Corrected `stats.pame_stats` columns (differs from Section 3.3 early sample)

Actual table has `pame_`-prefixed value columns (`pame_pa_marine`, `pame_pa_terrestrial`, `pame_pa_marine_pct`, `pame_pa_terrestrial_pct`, …), run id `metadata_pame_uuid`, and the same `metadata_*` columns as the other tables (37 columns total).

### Code map

| File | Role |
|------|------|
| `lib/modules/wdpa/portal/importers/stats_db_source/base.rb` | Run selection, NaN/percentage helpers, `MissingStatsError` |
| `lib/modules/wdpa/portal/importers/stats_db_source/national_stats.rb` | `stats.national_stats` → `staging_country_statistics` mapping |
| `lib/modules/wdpa/portal/importers/stats_db_source/pame_stats.rb` | `stats.pame_stats` → `staging_pame_statistics` mapping |
| `lib/modules/wdpa/portal/importers/stats_db_source/global_stats.rb` | `stats.global_stats` → overlay hash for `staging_global_statistics` |
| `lib/modules/wdpa/portal/importers/country_statistics.rb` | Source branch + NR merge (`import_stats_from_db`, `nr_attrs_by_iso3`) |
| `lib/modules/wdpa/shared/importer/global_stats.rb` | Source branch + CSV/DB hybrid merge (`import_to_staging`) |
| `lib/modules/wdpa/portal/import_runtime_config.rb` | `stats_source` config (`PP_STATS_SOURCE`) |
