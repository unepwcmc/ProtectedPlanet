# Base Datasets

We have some base datasets for countries, economic exclusive zones and terrotirial seas.
This dataset is on a postgres dump table on S3.

## How to get them

### Import to rails database

You will need do update your config/secrets.yaml file to include the bucket in S3 that has the table. 
Filename is currently 'countries_geometries_dump.tar.gz' (If it changes you need to change also in the import.rake rake task).
To import you will need to run:

```
rake import:countries_geometries
```

### Import to CartoDB
After doing the previous step you are now able to export in CartoDB compliant format (Shapefile,CSV, etc.).
To export as a shapefile from the database you can use ogr2ogr, shp2pgsql or even qgis.
After it you can upload the data manually to CartoDB.
 