# Downloads

Protected Planet allows users to download all, or subsets of, the WDPA
in a number of different formats, but three formats are common to every situation:
CSV, Shapefile or File Geodatabase. All downloads are required to contain the 
WDPA manual in English, Spanish, and French.


## Generation

There are currently four types of downloads: the entire WDPA, Protected Areas by
country or region, Protected Areas filtered by a search, and single Protected Areas.

All downloads are created in the backend via async requests initiated from the Vue
frontend. The frontend will poll the backend at regular intervals until the download
is ready, at which point a URL will be produced from the S3 hosted file and the 
download can be initiated.

The Download class is fairly naive and generates datasets for any given
array of WDPA IDs. It is the responsibility of the caller to decide what
is to be downloaded, and what the file should be saved as in S3.

```
Download.generate 'download_name', wdpa_ids: [123, 456, 2881]
```

### Data

The data for the downloads is produced from the unmodified WDPA import
tables.

As the polygon and points geometries are stored separately, we create a
postgres `VIEW` during import that is based on a `UNION` of the two
tables. This view is managed by `Wdpa::Release`.

### Caching

The downloads are cached after the first generation, using a hash of the search
terms or requested IDs. Downloads are then dropped every month, with the release
of a new WDPA version.

## Storage and access

Downloads are stored in S3 under the `pp-downloads-<environment>`
bucket. Each download is first prefixed with `WDPA_WDOECM_<timestamp of release>_Public`, 
given a name based on its contents, such as 'all' or 'AFG' (Country iso3) and 
combined with its type: `WDPA_WDOECM_Jun2021_Public_AFG_csv.zip`, and are retrieved based on this.

The Download class is responsible for generating links to downloads
given a name:

```
  Download.link_to '233', :csv
    #=> 'https://pp-downloads-production.s3.amazonaws.com/WDPA_WDOECM_Jun2021_Public_AFG_csv.zip'
```

## Shapefile notes

Shapefiles are only able to contain either polygons or points, and so
the Shapefile zip downloads consist of two Shapefiles for both the
WDPA polygon and points.
