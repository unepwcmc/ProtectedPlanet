# Green List Functionality

## Overview

The IUCN Green List of Protected and Conserved Areas is a global standard for protected areas. The Protected Planet application supports importing and displaying green list data for both **protected areas** and their **parcels**. Green list status can be set on the PA record and/or on individual parcels.

## Current Implementation

**Parcel-aware behaviour:** The PA and each parcel have their own `green_list_status_id`. A PA is considered green-listed for search/display if the PA record is green-listed **or** any of its parcels is green-listed. The application does not require all parcels to inherit the PA’s status; parcel-level status is supported.

**Search / indexing:** The `special_status` field used for filtering (e.g. “Green Listed”) is derived from `pa_or_any_its_parcels_is_greenlisted` and `pa_or_any_its_parcels_is_greenlist_candidate` on `ProtectedArea`, so a PA appears in Green List filters when it or any of its parcels is green-listed.

## Data Model

### Tables
- `green_list_statuses` – Status definitions (e.g. `gl_status`, `gl_expiry`, `gl_link`)
- `protected_areas` – `green_list_status_id` (optional), plus other PA attributes
- `protected_area_parcels` – `green_list_status_id` (optional) per parcel

### Relationships
- `ProtectedArea` `belongs_to` `GreenListStatus` (optional)
- `ProtectedAreaParcel` `belongs_to` `GreenListStatus` (optional)

## Scopes and queries

### ProtectedArea
- **`pas_with_green_list_on_self_only`** – PAs whose **own** record has a green list status (ignores parcels). Returns PA records.
- **`pas_with_green_list_on_self_or_any_parcel`** – PAs that are green-listed on the PA record **or** on any parcel. Returns **PA** records (not parcels); use `.protected_area_parcels` on each PA to get parcels.

### Instance methods (for search/indexing)
- **`pa_or_any_its_parcels_is_greenlisted`** – `true` if the PA or any of its parcels is Green Listed / Relisted.
- **`pa_or_any_its_parcels_is_greenlist_candidate`** – `true` if the PA or any of its parcels is a Candidate.

### Parcels
- Parcels with a green list status: `ProtectedAreaParcel.where.not(green_list_status_id: nil)` or join through `green_list_status`.

## Import Process

### Data sources
Green list data is sourced from the **portal materialised view**, not from CSV files. The view is created and refreshed as part of the portal release (e.g. via `FDW_VIEWS.sql`).

### Importers
- **Portal importer:** `Wdpa::Portal::Importers::GreenList` – reads from the green list materialised view via `Wdpa::Portal::Adapters::Greenlist` and imports into staging tables (`staging_protected_areas`, `staging_protected_area_parcels`, `staging_green_list_statuses`).

Import logic resolves each view row to a PA or parcel (by `site_id` / `site_pid`) and sets `green_list_status_id` on the corresponding record. The data model supports parcel-specific status when the view contains parcel-level rows.

## Usage

### Import
```ruby
# Portal importer (staging)
Wdpa::Portal::Importers::GreenList.import_to_staging(notifier: notifier)
```

### Query examples
```ruby
# PAs green-listed on the PA record only (no parcel logic)
ProtectedArea.pas_with_green_list_on_self_only

# PAs green-listed on the PA and/or on any parcel (returns PAs, not parcels)
ProtectedArea.pas_with_green_list_on_self_or_any_parcel

# Parcels that have a green list status
ProtectedAreaParcel.where.not(green_list_status_id: nil)
# Or with join:
ProtectedAreaParcel.joins(:green_list_status)
```

## Downloads

The general download worker uses green list to build the set of areas for the “greenlist” download type. It currently uses `ProtectedArea.pas_with_green_list_on_self_only` to collect `site_id`s.

## Related documentation
- [Protected Area Parcels](protected_area_parcels.md)
- [Release Process](./release/release_process.md)
