# CartoDB

CartoDB is used as the tile server, purely for rendering WDPA
geometries (this role was previously fulfilled by a Geoserver
instance).

The process of importing the WDPA in to CartoDB is fairly trivial as
no validation or modification of the data needs to be made. It
comprises three steps.

## Splitting the WDPA

The WDPA is too large to be imported in one go, so we split it in to
around 5 shapefiles using GDAL. During the splitting process, we
select only the WDPA ID and geometry to avoid the hassle of dealing
with problems caused by character encodings in plaintext fields.

## Uploading and importing

The resulting shapefiles are uploaded individually via the CartoDB
Import API. The Uploader module will wait for the import to complete
and then report success/failure.

## Merging

As we had to split the files up, they will be represented by
individual tables on CartoDB. The Merger module runs `UNION` SQL
queries on the CartoDB tables to collate all the geometries in to a
single table.
