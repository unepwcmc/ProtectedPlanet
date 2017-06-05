# Downloads

Protected Planet allows users to download all, or subsets of, the WDPA
in three formats: CSV, KML and Shapefile. All downloads are required to
contain the WDPA manual in English, Spanish, and French.

## Generation

There are currently four types of downloads: the entire WDPA, Protected
Areas by country -- both statically generated --, Protected Areas
filtered by a search, and single Protected Areas.

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
bucket. Each download is given a name based on its contents, such as
'all' or '233' (Country ID) and combined with its type: `all-csv.zip`,
`233-kml.zip` and are retrieved based on this.

The Download class is responsible for generating links to downloads
given a name:

```
  Download.link_to '233', :csv
    #=> 'https://pp-downloads-production.s3.amazonaws.com/233-csv.zip'
```

## Shapefile notes

Shapefiles are only able to contain either polygons or points, and so
the Shapefile zip downloads consist of two Shapefiles for both the
WDPA polygon and points.
