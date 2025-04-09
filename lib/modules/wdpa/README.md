# WDPA Modules

This set of modules encapsulates the behaviour for handling the WDPA
dataset: downloading, retrieving metadata, importing, etc.

## Data Standard

The [WDPA Data Standard](data_standard.rb) defines the attributes that
make up the WDPA dataset, and how they map to attributes used in this
application. It acts as a manager for incoming WDPA data by
standardising the data, and creating `ActiveRecord` relations.

Check out the [WDPA Manual](http://wcmc.io/WDPA_Manual) for more
information.

## Releases

The WDPA is released approximately at the end of every month. These
releases are represented internally as `Wdpa::Release` objects, which
handle getting the releases in to Rails. `Release` objects are created
during Imports, by `Wdpa::Importer`.

The following tasks occur on a release when an Import is run.

### Downloading

Currently the WDPA is stored each month in AWS S3. `Wdpa::S3` represents
a WDPA storage medium, and implements methods to download and save the
WDPA from S3.

The WDPA is downloaded as a File Geodatabase.

### Importing

GDAL's `ogr2ogr` imports the File Geodatabase in to the current Rails
database, keeping the table names defined by the WDPA.

### Standardisation

`Wdpa::DataStandard` and `Wdpa::ParcelDataStandard` (see above) converts the GDB imported data (which
is constrained by limitations, such as column name length) in to
standardised hashes of
`Wdpa::DataStandard` -> [ProtectedArea](../../../app/models/protected_area.rb) attributes and
relations.
`Wdpa::ParcelDataStandard` -> [ProtectedAreaParcel](../../../app/models/protected_area_parcel.rb) attributes and
relations.

### Creating Protected Areas

`Wdpa::ProtectedAreaImporter::AttributesImporter` takes the array of
attributes from the standardisation process and creates the
Protected Areas and Parcels (if a PA has multiple parcels) in the Rails database through `ProtectedArea#create` and `ProtectedAreaParcel#create`.

### Importing Geometries

`Wdpa::ProtectedAreaImporter::GeometryImporter` imports the Protected
Area geometries on to the matching `ProtectedArea` models. It does so
through an `UPDATE` SQL query, for performance reasons (primarily to
avoid the ActiveRecord Postgis Adapter).
TODO: think about adding Geometry to ProtectedAreaParcel but only if it is needed as this takes a lot of space in db

### Cleanup

The WDPA import tables aren't used in the general running of the
application, but are kept so that we can generate downloads with the
WDPA Data Standard without having to re-transform the data back to how
it started.

The cleanup step only removes the downloaded WDPA GDB files.
