# Downloads

Protected Planet allows users to download all, or subsets of, the WDPA
in a number of different formats, but three formats are common to every situation:
CSV, Shapefile or File Geodatabase. All downloads are required to contain the 
WDPA manual and supporting documentation. The manual is available in multiple languages
including English, Spanish, French, Russian, and Arabic, along with metadata and
summary tables.

Country and region pages also have PDF downloads available, which uses a Node.js script
(`rasterize.js`) that leverages Puppeteer to render a snapshot of the page as a PDF,
essentially producing a factsheet.

On the WDPA and WDOECM thematic area pages, the two layers each have a direct link
to the ESRI server which hosts them.

## Generation

There are currently four types of downloads: the entire WDPA, Protected Areas by
country or region, Protected Areas filtered by a search, and single Protected Areas.

All downloads are created in the backend via async requests initiated from the Vue
frontend (the Download button). The frontend polls the backend at regular intervals 
until the download is ready, at which point a URL will be produced from the S3 
hosted file and the download can be initiated.

The Download class is fairly naive and generates datasets for any given
array of SITE IDs. It is the responsibility of the caller to decide what
is to be downloaded, and what the file should be saved as in S3.

```
Download.generate 'download_name', site_ids: [123, 456, 2881]
```

### Data

The data for the downloads is produced from the unmodified WDPA import
tables.

As the polygon and points geometries are stored separately, we create a
postgres `VIEW` during import that is based on a `UNION` of the two
tables. This view is managed by `Download::Config.downloads_view`, which
selects the appropriate view based on whether a portal release exists
(uses portal materialized views) or falls back to the standard WDPA release
views managed by `Wdpa::Release`.

### Caching

The downloads are cached after the first generation using Redis. The caching strategy
varies by download type:

- **Search downloads**: Uses a SHA256 hash of the search terms and filters as the cache key
- **General/Country/Region downloads**: Uses the identifier (e.g., country ISO3, region ISO) as the cache key
- **Protected Area downloads**: Uses the site ID as the cache key

Downloads are then dropped every month, with the release of a new WDPA version.

## Storage and access

Downloads are stored in S3 under the `pp-downloads-<environment>`
bucket. Each download is prefixed with either `current/` (for regular downloads)
or `import/` (for import-related downloads).

The file naming convention follows this pattern:
- Base: `WDPA_WDOECM_<release_label>_Public`
- Identifier suffix (for country/region/search/PA): `_<identifier>`
- Format suffix (for CSV/Shapefile, nothing added for GDB): `_<format>`
- Extension: `.zip`

Example: `WDPA_WDOECM_Jun2021_Public_AFG_csv.zip`

Downloads generated via the search are provided a SHA256 hash which takes the place of 
the identifier in the filename.

The Download class is responsible for generating links to downloads
given a download name (which already includes the format):

```
  Download.link_to 'WDPA_WDOECM_Jun2021_Public_AFG_csv'
    #=> 'https://pp-downloads-production.s3.amazonaws.com/current/WDPA_WDOECM_Jun2021_Public_AFG_csv.zip'
```

## Known issues (staging)

### 18 Dec 2025 - \"Ready\" link returns `NoSuchKey`

On staging, a download can sometimes be reported as `ready` (based on Redis status) while the S3 URL returns `NoSuchKey`.

When investigating:
- Confirm the Redis key for the download and its `status`/`filename`.
- Confirm Sidekiq actually processed a job (do not rely on queue length alone).
- Confirm the object exists in the configured downloads bucket/prefix:
  - bucket: `Rails.application.secrets.aws_downloads_bucket`
  - URL base: `Rails.application.secrets.aws_s3_url`
  - object key prefix: `current/`

## Shapefile notes

Shapefiles are only able to contain either polygons or points, and so
the Shapefile zip downloads consist of two Shapefiles for both the
WDPA polygon and points.
