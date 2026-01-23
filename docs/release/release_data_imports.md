# Release Data Imports

This document describes all the data types that are imported during a Protected Planet release. The release process imports data from the [Data Management Portal](https://pp-data-management-portal.org) into Protected Planet's database.

## Overview

During a release, data flows through a staging process:
1. **Staging tables** are created as copies of live tables
2. **Data is imported** into staging tables from portal materialized views
3. **Validation** occurs on staging data
4. **Atomic swap** moves staging data to live tables (with backups)

## Core Data Imports

### 1. Protected Areas

**Source**: Portal materialized views (`portal_standard_polygons`, `portal_standard_points`)

**Tables**:
- `protected_areas` - Main protected area records (one per site, with first parcel as representative)
- `protected_area_parcels` - All parcels for protected areas (including first parcel)

**What's imported**:
- Protected area attributes (name, designation, IUCN category, status, etc.)
- Geometry data (polygons and points)
- Site relationships and metadata
- Parcel information for sites with multiple parcels

**Importer**: `Wdpa::Portal::Importers::ProtectedArea`
- Attributes: `Wdpa::Portal::Importers::ProtectedArea::Attribute`
- Geometry: `Wdpa::Portal::Importers::ProtectedArea::Geometry`

**File locations**:
- [`lib/modules/wdpa/portal/importers/protected_area.rb`](../../lib/modules/wdpa/portal/importers/protected_area.rb)
- [`lib/modules/wdpa/portal/importers/protected_area/attribute.rb`](../../lib/modules/wdpa/portal/importers/protected_area/attribute.rb)
- [`lib/modules/wdpa/portal/importers/protected_area/geometry.rb`](../../lib/modules/wdpa/portal/importers/protected_area/geometry.rb)

**See also**: [Protected Area Parcels Documentation](../protected_area_parcels.md)

### 2. Sources

**Source**: Portal materialized view (`portal_standard_sources`)

**Table**: `sources`

**What's imported**:
- Data source information for protected areas
- Source metadata and attribution

**Importer**: `Wdpa::Portal::Importers::ProtectedAreaSource`

**File location**: [`lib/modules/wdpa/portal/importers/source.rb`](../../lib/modules/wdpa/portal/importers/source.rb)

### 3. Protected Area Sources (Junction Table)

**Source**: Derived from protected areas and sources relationships

**Table**: `protected_areas_sources` (junction table)

**What's imported**:
- Many-to-many relationships between protected areas and their data sources

**Importer**: `Wdpa::Shared::Importer::ProtectedAreasRelatedSource`

**File location**: [`lib/modules/wdpa/shared/importer/protected_areas_related_source.rb`](../../lib/modules/wdpa/shared/importer/protected_areas_related_source.rb)

## Statistics Data

### 4. Country Statistics

**Source**: CSV files (`country_statistics_<YYYY-MM>-01.csv`)

**Table**: `country_statistics`

**What's imported**:
- Country-level protected area coverage statistics
- Land and marine area percentages
- EEZ and Territorial Seas coverage
- Protected area counts (polygons and points)
- OECM statistics

**Importer**: `Wdpa::Portal::Importers::CountryStatistics`

**File location**: [`lib/modules/wdpa/portal/importers/country_statistics.rb`](../../lib/modules/wdpa/portal/importers/country_statistics.rb)

**Note**: Statistics are now provided by the Protected Areas Programme team via CSV files, not calculated dynamically. See [Statistics Documentation](../statistics.md) for historical calculation methods.

### 5. Country Protected Area Geometry Statistics

**Source**: Portal materialized views (calculated from protected area geometries)

**Table**: `country_statistics` (geometry count fields)

**What's imported**:
- Protected area polygon count per country
- Protected area point count per country
- OECM polygon count per country
- OECM point count per country

**Importer**: `Wdpa::Portal::Importers::CountriesProtectedAreaGeometryStatistics`

**File location**: [`lib/modules/wdpa/portal/importers/countries_protected_area_geometry_statistics.rb`](../../lib/modules/wdpa/portal/importers/countries_protected_area_geometry_statistics.rb)

### 6. Global Statistics

**Source**: CSV files (`global_statistics_<YYYY-MM>-01.csv`)

**Table**: `global_statistics`

**What's imported**:
- Global-level protected area coverage statistics
- Worldwide percentages and totals

**Importer**: `Wdpa::Shared::Importer::GlobalStats`

**File location**: [`lib/modules/wdpa/shared/importer/global_stats.rb`](../../lib/modules/wdpa/shared/importer/global_stats.rb)

## PAME (Protected Area Management Effectiveness) Data

### 7. PAME Evaluations

**Source**: CSV files (`pame_data_<YYYY-MM>-01.csv`)

**Table**: `pame_evaluations`

**What's imported**:
- Management effectiveness evaluations
- Assessment metadata and dates
- Evaluation results and scores

**Importer**: `Wdpa::Portal::Importers::Pame`

**File location**: [`lib/modules/wdpa/portal/importers/pame.rb`](../../lib/modules/wdpa/portal/importers/pame.rb)

### 8. PAME Sources

**Source**: Derived from PAME data

**Table**: `pame_sources`

**What's imported**:
- Source information for PAME evaluations

**Importer**: `Wdpa::Portal::Importers::Pame`

**File location**: [`lib/modules/wdpa/portal/importers/pame.rb`](../../lib/modules/wdpa/portal/importers/pame.rb)

### 9. PAME Statistics

**Source**: CSV files (`pame_country_statistics_<YYYY-MM>-01.csv`)

**Table**: `pame_statistics`

**What's imported**:
- Country-level PAME statistics
- Assessment counts per country
- Assessed protected area counts

**Importer**: `Wdpa::Portal::Importers::CountryStatistics` (PAME component)

## Green List Data

### 10. Green List Status

**Source**: CSV files (`green_list_sites_<YYYY-MM>-01.csv`)

**Table**: `green_list_statuses`

**What's imported**:
- Green List certification status
- Certification dates
- Green List URLs
- Status information for protected areas

**Importer**: `Wdpa::Portal::Importers::GreenList`

**File location**: [`lib/modules/wdpa/portal/importers/green_list.rb`](../../lib/modules/wdpa/portal/importers/green_list.rb)

**See also**: [Green List Documentation](../green_list.md)

## Additional Data

### 11. Story Map Links

**Source**: CSV files or configuration

**Table**: `story_map_links`

**What's imported**:
- Links to story maps for protected areas
- Story map metadata

**Importer**: `Wdpa::Shared::Importer::StoryMapLinkList`

**File location**: [`lib/modules/wdpa/shared/importer/story_map_link_list.rb`](../../lib/modules/wdpa/shared/importer/story_map_link_list.rb)

## Live Table Updates (Non-Staging)

These tables are updated directly in live tables (not through staging):

### 12. Country Overseas Territories

**Table**: `countries` (overseas territories fields)

**What's updated**:
- Overseas territory relationships
- Territory metadata

**Importer**: `Wdpa::Shared::Importer::CountryOverseasTerritories.update_live_table`

**File location**: [`lib/modules/wdpa/shared/importer/country_overseas_territories.rb`](../../lib/modules/wdpa/shared/importer/country_overseas_territories.rb)

### 13. BIOPAMA Countries

**Table**: `countries` (BIOPAMA fields)

**What's updated**:
- BIOPAMA country flags and metadata

**Importer**: `Wdpa::Shared::Importer::BiopamaCountries.update_live_table`

**File location**: [`lib/modules/wdpa/shared/importer/biopama_countries.rb`](../../lib/modules/wdpa/shared/importer/biopama_countries.rb)

**Note**: As of 05Sep2025, this may not be actively used.

### 14. Aichi 11 Target

**Table**: `aichi11_targets`

**What's updated**:
- Aichi Target 11 global statistics
- Target achievement metrics

**Importer**: `Aichi11Target.update_live_table`

**File location**: [`app/models/aichi11_target.rb`](../../app/models/aichi11_target.rb)

**Note**: As of 05Sep2025, this may not be actively used.

## Import Order

The importers run in a specific order to respect dependencies:

1. **Sources** - Independent, no dependencies
2. **Protected Areas** (attributes and geometry) - Core data
3. **Protected Area Sources** - Depends on protected areas and sources
4. **Global Statistics** - Depends on protected areas
5. **Green List** - Depends on protected areas
6. **PAME** - Depends on protected areas
7. **Story Map Links** - Depends on protected areas
8. **Country Statistics** - Depends on protected areas

If protected areas import fails with hard errors, subsequent importers are skipped.

## Data Sources

### Portal Materialized Views

Data is primarily sourced from materialized views in the Data Management Portal database:

- `portal_standard_polygons` - Protected area polygons
- `portal_standard_points` - Protected area points
- `portal_standard_sources` - Source data
- Staging versions: `staging_portal_standard_polygons`, `staging_portal_standard_points`, etc.

### CSV Files

Statistics and related data come from CSV files in `lib/data/seeds/`:

- `country_statistics_<YYYY-MM>-01.csv`
- `global_statistics_<YYYY-MM>-01.csv`
- `pame_country_statistics_<YYYY-MM>-01.csv`
- `pame_data_<YYYY-MM>-01.csv`
- `green_list_sites_<YYYY-MM>-01.csv`

**See**: [Release Process Documentation](release_process.md) for details on CSV file preparation.

## Staging Process

All data (except live table updates) goes through staging:

1. **Staging tables** are created with `staging_` prefix
2. **Data is imported** into staging tables
3. **Validation** checks data integrity
4. **Atomic swap** moves staging → live (with backups)

This ensures data consistency and allows rollback if needed.

## Related Documentation

- [Monthly Release Process](release_process.md) - Step-by-step release guide
- [Portal Release Runbook](portal_release_runbook.md) - Developer commands and workflows
- [Release Orchestration](release_orchestration.md) - Technical architecture details
- [Protected Area Parcels](../protected_area_parcels.md) - Understanding parcels
- [Green List](../green_list.md) - Green List functionality
- [Statistics](../statistics.md) - Historical statistics calculation (now deprecated)

