# Downloads

Users can download all of the WDPA, or a subset, as **CSV, Shapefile or File
Geodatabase**. Every download also contains the WDPA manual (English, Spanish,
French, Russian, Arabic), metadata and summary tables.

Country and region pages additionally offer a **PDF factsheet**, rendered by
Puppeteer in `app/frontend/backend-scripts/rasterize.js`. The WDPA and WDOECM
thematic pages link straight to the ESRI server hosting those layers.

## Generation

Four kinds: the entire WDPA, by country or region, by search, and a single
protected area.

All are built asynchronously. The Vue 3 Download button posts to the backend, the
frontend polls until the file is ready, and the response carries an S3 URL.

`Download` is deliberately naive — it generates a dataset for any array of site
IDs. The caller decides what to download and what to call it in S3.

```ruby
# format is one of :csv, :shp, :gdb, :pdf
Download.generate :csv, 'download_name', { site_selection: { site_ids: [123, 456, 2881] } }
```

### Data

Polygon and point geometries are stored separately, so the downloads read a
`UNION` of the two: `Download::Config.downloads_view`, which resolves to the
portal materialized view `portal_downloads_protected_areas`.

### Caching

Generated downloads are cached in Redis, keyed by type:

- **Search** — SHA256 of the search terms and filters
- **General / country / region** — the identifier (country ISO3, region ISO)
- **Protected area** — the site ID

The cache is dropped each month with the new WDPA release.

## Storage and access

Downloads live in S3 under `pp-downloads-<environment>`, prefixed `current/` for
regular downloads or `import/` for import-related ones.

Filenames are `WDPA_WDOECM_<release_label>_Public`, plus an identifier for
country/region/search/PA downloads, plus a format suffix for CSV and Shapefile
(nothing for GDB), then `.zip` — e.g. `WDPA_WDOECM_Jun2021_Public_AFG_csv.zip`.
Search downloads use their SHA256 hash as the identifier.

`Download.link_to` builds the URL from a name that already includes the format:

```ruby
Download.link_to 'WDPA_WDOECM_Jun2021_Public_AFG_csv'
#=> 'https://pp-downloads-production.s3.amazonaws.com/current/WDPA_WDOECM_Jun2021_Public_AFG_csv.zip'
```

## Shapefiles

A Shapefile holds either polygons or points, never both, so a Shapefile zip
contains two: one for the WDPA polygons, one for the points.
