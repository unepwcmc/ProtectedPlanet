# Green List

The [IUCN Green List](https://iucngreenlist.org) of Protected and Conserved Areas
is a global standard for protected areas. Protected Planet imports and displays
Green List status for both **protected areas and their parcels**.

## Status lives in two places

`protected_areas` and `protected_area_parcels` each have their own optional
`green_list_status_id` (both `belongs_to :green_list_status, optional: true`).
A parcel does **not** inherit the PA's status.

A site counts as green-listed when the PA record **or any** of its parcels is —
see [protected areas and parcels](protected_area_parcels.md).

`green_list_statuses` holds the status definitions (`gl_status`, `gl_expiry`,
`gl_link`).

## Scopes and methods

On `ProtectedArea` (`app/models/protected_area.rb`):

| | Returns |
|---|---|
| `pas_with_green_list_on_self_only` | PAs green-listed on their **own** record, ignoring parcels |
| `pas_with_green_list_on_self_or_any_parcel` | PAs green-listed on the record **or** any parcel — **PA** records, not parcels; use `.protected_area_parcels` to reach those |
| `#pa_or_any_its_parcels_is_greenlisted` | `true` if the PA or any parcel is Green Listed / Relisted |
| `#pa_or_any_its_parcels_is_greenlist_candidate` | `true` if the PA or any parcel is a Candidate |

Parcels with a status: `ProtectedAreaParcel.where.not(green_list_status_id: nil)`,
or `ProtectedAreaParcel.joins(:green_list_status)`.

## Search

`ProtectedArea#special_status` builds the `Green Listed` / `Candidate` filter
values from the two instance methods above, so a PA appears in Green List filters
when it *or any parcel* qualifies.

## Import

Green List data comes from the **portal materialised view**, not from CSV. The
view is created and refreshed as part of the release (see `FDW_VIEWS.sql`).

`Wdpa::Portal::Importers::GreenList` reads it through
`Wdpa::Portal::Adapters::ImportViewsAdapter`, resolves each row to a PA or parcel
by `site_id` / `site_pid`, and writes into `staging_green_list_statuses`,
`staging_protected_areas` and `staging_protected_area_parcels`.

```ruby
Wdpa::Portal::Importers::GreenList.import_to_staging(notifier: notifier)
```

## Downloads

The "greenlist" download type collects its `site_id`s from
`ProtectedArea.pas_with_green_list_on_self_only` — PA-level status only, parcels
excluded (`app/workers/download_workers/base.rb`).

## See also

- [Protected areas and parcels](protected_area_parcels.md)
- [Release process](release/release_process.md)
