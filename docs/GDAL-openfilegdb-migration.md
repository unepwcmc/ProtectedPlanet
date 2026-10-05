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
no proprietary dependency. **Both images are on it** — `Dockerfile` (dev) and
`Dockerfile.deploy` — so the driver behaves the same locally and on the deployed hosts.

The **`gdal` Ruby gem was also removed** — it is pinned `~> 2.0` and only compiles against GDAL
2.x (it calls C API functions removed in GDAL 3: `OSRStripCTParms`, `OSRFixup`,
`OPTGetParameterInfo`, …). Everything it was used for (layer count, layer names, feature count)
now comes from the `ogrinfo -json` CLI via `Ogr::Info`, which shells out.

## The one thing that is NOT a drop-in: the geometry column name

**OpenFileGDB names the geometry column after the source column**, whereas the ESRI SDK always
named it **`SHAPE`**. Left alone this silently changes the schema of every `.gdb` we ship — the
downloads view exposes its geometry as `WKB_GEOMETRY`, so that is what the layer would be called.

Fixed by forcing it in `lib/modules/ogr/command_templates/postgres_gdb_export.erb`:

```
-lco "GEOMETRY_NAME=SHAPE"
```

## Verified output parity

Originally checked OLD (`FileGDB`, GDAL 2.2.3 image) against NEW (`OpenFileGDB`, GDAL 3.6.2,
Debian bookworm). **Re-verified 2026-09-02 in-app on GDAL 3.8.4** (dev container, Ubuntu 24.04),
driving `Ogr::Postgres.export` on real `portal_downloads_protected_areas` data — the app's own
code path and template, not a hand-written `ogr2ogr`:

| Property | poly | point | source |
|---|---|---|---|
| Geometry type | Multi Polygon ✔ | Multi Point ✔ | None ✔ |
| FID column | `OBJECTID` ✔ | `OBJECTID` ✔ | `OBJECTID` ✔ |
| Geometry column | `SHAPE` ✔ | `SHAPE` ✔ | n/a |
| CRS | WGS 84 / EPSG:4326 ✔ | ✔ | n/a |
| Features in → out | 20 → 20 ✔ | 4 → 4 ✔ | 10 → 10 ✔ |

✔ = identical to the old FileGDB output. Layer naming
(`WDPA_WDOECM_{poly,point,source}_MmmYYYY`) is applied by `Ogr::Postgres.get_feature_name` and
came out as expected.

Multi-layer assembly also matches: the first layer is written with `-f OpenFileGDB`, subsequent
layers appended into the same `.gdb` with `-update`.

**Only known difference — cosmetic:** the CRS is serialised as WKT2 (`GEOGCRS[...]`) by GDAL 3.6+
instead of WKT1 (`GEOGCS[...]`) by GDAL 2.2.3. Same CRS (EPSG:4326); a newer-GDAL artefact, not a
driver difference.

### Reproducing the check

The template wraps the query in single quotes and `squish`es the command, so a test query must
contain **no single quotes of its own**. Geometry must also be wrapped in `ST_Multi()` and the
`geom_type` passed as `multipolygon` / `multipoint` — this is what
`Download::Generators::Gdb#with_multi_geom` does, and without it `-skipfailures` silently drops
every feature stored as `POLYGON` rather than `MULTIPOLYGON`. The filename must follow the
`WDPA_WDOECM_MmmYYYY_Public.gdb` convention or `get_feature_name` raises.

## Other download formats are unaffected

The change touches only `DRIVERS[:gdb]` and the `.gdb` template. **CSV** (`CSV`) and **Shapefile**
(`ESRI Shapefile`) use unchanged drivers and the untouched `postgres_export.erb`; PDF is a separate
generator.

## Prior art

`wdpa-data-management-portal` already ships the same WDPA `.gdb` via OpenFileGDB on stock apt GDAL
in production — see its `app/services/downloads/gdb_exporter.rb`. Its command additionally sets
`-lco FID=OBJECTID`, `-a_srs EPSG:4326` and `--config PG_USE_COPY YES`; we did not adopt those
because our output already matches the old files without them (see the table above), and the goal
here was parity, not change.

## Still outstanding

- **Data-team sign-off** that a real released `.gdb` opens correctly in ArcGIS. Largely
  pre-answered by the portal shipping OpenFileGDB output already, but worth confirming on a full
  release.
- Parity was checked on **samples** (20 polygons / 4 points / 10 sources), not a full release
  volume.
