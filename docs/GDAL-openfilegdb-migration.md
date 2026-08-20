# GDAL: ESRI FileGDB SDK → OpenFileGDB

`.gdb` (File Geodatabase) downloads are produced by `ogr2ogr` reading from PostGIS. GDAL
offers two drivers that can write that format:

| Driver | Notes |
|---|---|
| `FileGDB` (old) | Needs ESRI's **proprietary** FileGDB SDK compiled into GDAL. ESRI ship it as a **RHEL7 binary linked against an old glibc**. |
| `OpenFileGDB` (now) | **Built into GDAL**, no SDK. Read-only until GDAL 3.6; **writes `.gdb` from 3.6 onward**. Reports as `rw+v`. |

## Why we moved

The old chain pinned us to a dead platform: the image had to source-build **GDAL 2.2.3** and
link the ESRI SDK, and that SDK binary **cannot be built on a current base image**. It blocked
the move to Ubuntu 24.04.

Now: Ubuntu 24.04 + **distro GDAL 3.8.4** (`gdal-bin` from apt) + OpenFileGDB. No source build,
no proprietary dependency.

The **`gdal` Ruby gem was also removed** — it is pinned `~> 2.0` and only compiles against GDAL
2.x (it calls C API functions removed in GDAL 3: `OSRStripCTParms`, `OSRFixup`,
`OPTGetParameterInfo`, …). Everything it was used for (layer count, layer names, feature count)
now comes from the `ogrinfo -json` CLI via `Ogr::Info`, which shells out.

## The one thing that is NOT a drop-in: the geometry column name

**OpenFileGDB names the geometry column after the source column** (`the_geom`), whereas the ESRI
SDK named it **`SHAPE`**. Left alone this silently changes the schema of every `.gdb` we ship.

Fixed by forcing it in `lib/modules/ogr/command_templates/postgres_gdb_export.erb`:

```
-lco "GEOMETRY_NAME=SHAPE"
```

## Verified output parity

Both versions were generated from the same PostGIS data and compared — OLD via `FileGDB` on the
GDAL 2.2.3 image, NEW via `OpenFileGDB` on GDAL 3.6.2 (Debian bookworm, apt, no SDK):

| Property | poly | point | source |
|---|---|---|---|
| Geometry type | Multi Polygon ✔ | Multi Point ✔ | None ✔ |
| Feature count | 20 ✔ | 5 ✔ | 10 ✔ |
| FID column | `OBJECTID` ✔ | `OBJECTID` ✔ | `OBJECTID` ✔ |
| Geometry column | `SHAPE` ✔ | `SHAPE` ✔ | n/a |
| Fields | match ✔ | match ✔ | match ✔ |
| CRS | WGS 84 / EPSG:4326 ✔ | ✔ | n/a |

✔ = identical to the old FileGDB output.

Multi-layer assembly also matches: the first layer is written with `-f OpenFileGDB`, subsequent
layers appended into the same `.gdb` with `-update`.

**Only known difference — cosmetic:** the CRS is serialised as WKT2 (`GEOGCRS[...]`) by GDAL 3.6+
instead of WKT1 (`GEOGCS[...]`) by GDAL 2.2.3. Same CRS (EPSG:4326); a newer-GDAL artefact, not a
driver difference.

## Other download formats are unaffected

The change touches only `DRIVERS[:gdb]` and the `.gdb` template. **CSV** (`CSV`) and **Shapefile**
(`ESRI Shapefile`) use unchanged drivers and the untouched `postgres_export.erb`; PDF is a separate
generator.

## Prior art

`wdpa-data-management-portal` already ships the same WDPA `.gdb` via OpenFileGDB on stock apt GDAL
(Debian bookworm) in production — see its `app/services/downloads/gdb_exporter.rb`. Its command
additionally sets `-lco FID=OBJECTID`, `-a_srs EPSG:4326` and `--config PG_USE_COPY YES`; we did
not adopt those because our output already matches the old files without them (see the table
above), and the goal here was parity, not change.

## Still outstanding

- **In-app end-to-end run** on the GDAL 3.8 image. The dev image is still GDAL 2.2.3, where
  OpenFileGDB is read-only, so the swap cannot be exercised through the app locally — it needs the
  `Dockerfile.deploy` image on staging (`pp-web-staging-01`).
- **Data-team sign-off** that a real released `.gdb` opens correctly in ArcGIS. Largely
  pre-answered by the portal shipping OpenFileGDB output already, but worth confirming on a full
  release.
- Parity was checked on **samples** (20 polygons / 5 points), not a full release volume.
