# Protected areas and parcels

A protected area can have more than one **parcel**, each with its own attributes
and geometry.

- `protected_areas` — one row per site. Where a site has multiple parcels, the
  **first parcel is stored here as the representative**.
- `protected_area_parcels` — every parcel, *including* the first. So a
  multi-parcel site's first parcel exists in both tables.
- Linked by `site_id` (`foreign_key: 'site_id', primary_key: 'site_id'`) — see
  [protected_area.rb](/app/models/protected_area.rb) and
  [protected_area_parcel.rb](/app/models/protected_area_parcel.rb).

## ⚠️ Calculations

**Anything you compute per-site must account for multiple parcels**, or it will
silently only reflect the first one. See `reported_area` in
[protected_areas_helper.rb](/app/helpers/protected_areas_helper.rb) for the
pattern.

## Import

Data comes from the portal materialized views `portal_standard_polygons` and
`portal_standard_points` (or their `staging_*` versions during a release). The
same `site_id` appears once per parcel (`site_pid`).

See [attribute.rb](/lib/modules/wdpa/portal/importers/protected_area/attribute.rb)
for how the two tables are populated, and
[Release data imports](release/release_data_imports.md) for the wider picture.

## Green List

Both tables carry `green_list_status_id` and `gl_link`, and they are set
**independently** — a parcel does not inherit the PA's status. A site counts as
green-listed for search and display if the PA record **or any** of its parcels
is. See [green_list.md](green_list.md).

## Frontend

[protected_area_presenter.rb](/app/presenters/protected_area_presenter.rb) shows
how parcels reach the views (including the parcel dropdown on the PA page).
