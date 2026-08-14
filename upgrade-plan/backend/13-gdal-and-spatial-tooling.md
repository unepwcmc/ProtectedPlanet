# 13 — GDAL & spatial tooling — drop the ESRI FileGDB dependency

| | |
|---|---|
| **Estimate** | 1–2 weeks · ~0.25–0.5 month (plus data-team validation time) |
| **Depends on** | [02 — Ruby upgrade](./02-ruby-upgrade.md) |
| **Blocks** | **[11 — Docker + Kamal 2](./11-deploy-and-devops.md)** (hard prerequisite) · [12 — Infrastructure](./12-infrastructure-migration.md) |

[← Back to overview](./README.md)

---

## Goal

Move off GDAL 2.2.3 and the proprietary ESRI FileGDB SDK, onto **distro GDAL 3.8** using the open `OpenFileGDB` driver — and remove the abandoned `gdal` Ruby gem.

This is the single largest piece of work hiding inside "dockerize the project", and it is the reason dockerization is not just a packaging exercise.

---

## The problem

Our `.gdb` downloads depend on a chain that cannot be carried onto a modern base image:

| Layer | Current state | Why it breaks |
|---|---|---|
| `.gdb` export | `lib/modules/ogr/postgres.rb` shells `ogr2ogr` with the **`FileGDB`** driver | That driver requires ESRI's closed-source FileGDB API SDK |
| ESRI SDK | `FileGDB_API-RHEL7-64gcc83` downloaded from GitHub in the `Dockerfile`, copied into `/usr/local` | Unmaintained RHEL7-era binary blob |
| GDAL | **2.2.3 (2017) compiled from source** with `--with-fgdb`, ~40 `--without-*` flags | Will not build cleanly on Ubuntu 24.04 / gcc 13 |
| Ruby bindings | `gdal (2.0.0)` gem — old **gdal-ruby SWIG** bindings, `require 'gdal-ruby/ogr'` | Abandoned; compiles against GDAL 2.x only |

Carrying this stack forward onto Ubuntu 24.04 is not viable. Rebuilding it from source on a modern toolchain is a dead end.

---

## The fix

**GDAL ≥ 3.6's `OpenFileGDB` driver supports *writing* `.gdb`.** That removes the reason the proprietary SDK exists in our stack at all.

Ubuntu 24.04 ships **GDAL 3.8.4** in the standard repos — comfortably past that bar. So:

- ESRI SDK → **deleted**
- GDAL source build → **deleted**, replaced with `apt install gdal-bin libgdal-dev`
- `gdal` gem → **deleted**, replaced with `ogrinfo` shell-outs

The Dockerfile loses roughly 60 lines and the image loses a large layer.

---

## Work item 1 — swap the driver

`lib/modules/ogr/postgres.rb:11`:

```ruby
DRIVERS = {
  shapefile: 'ESRI Shapefile',
  csv: 'CSV',
  gdb: 'FileGDB'        # → 'OpenFileGDB'
}
```

- [ ] Change `FileGDB` → `OpenFileGDB`
- [ ] Review the ERB command templates in `lib/modules/ogr/command_templates/` — `postgres_gdb_export.erb` in particular. Driver-specific creation options and layer options differ between the two drivers
- [ ] Re-check the `-update` flag path (`needs_updating` in `Ogr::Postgres.export`) — multiple layers (poly / point / source) are written into the same `.gdb`, and `OpenFileGDB` handles append differently
- [ ] Confirm field name truncation and type mapping still match the previous output

---

## Work item 2 — remove the `gdal` gem

The gem is used in exactly two places, both thin:

| File | Lines | Uses |
|---|---|---|
| `lib/modules/ogr/info.rb` | 31 | `layer_count`, `layers`, `layers_matching`, `feature_count` |
| `lib/modules/ogr/split.rb` | 43 | Calls `Ogr::Info#feature_count` only |

Callers: `lib/modules/wdpa/release.rb` (`Ogr::Info.new(gdb_path)` for layer discovery and feature counts).

- [ ] Reimplement `Ogr::Info` on top of `ogrinfo -json <path>` and parse the JSON — layer names and feature counts are both in that output
- [ ] Keep the public interface identical so `Ogr::Split` and `Wdpa::Release` are untouched
- [ ] Remove `require 'gdal-ruby/ogr'` from both files
- [ ] Remove `gem 'gdal', '~> 2.0'` from the Gemfile
- [ ] This also removes a native extension from the Ruby 3.3 compatibility surface — see [02](./02-ruby-upgrade.md), which currently lists `gdal` as a native-ext risk

Roughly 50 lines of replacement code for a whole abandoned native dependency.

---

## Work item 3 — related cleanups in the same file

`lib/modules/ogr/postgres.rb` also contains:

- [ ] `Ogr::Postgres.db_config` calls `ActiveRecord::Base.connection_config` — **removed in Rails 7**. Replace with `ActiveRecord::Base.connection_db_config.configuration_hash`. This is on the Rails 7 list anyway ([04](./04-rails-7.md)) but lives here
- [ ] `log_command_to_file` is dead debug code — remove or gate it
- [ ] Commented-out `Rails.logger.info` debug lines throughout `Ogr::Postgres` and `Download::Generators::Gdb` — clean up while in here

---

## Validation — this is the gate, not the code change

Our `.gdb` outputs are consumed downstream by external users in ArcGIS. "The file exists and unzips" is **not** sufficient acceptance.

### Byte-level / structural comparison

- [ ] Generate a full WDPA `.gdb` download on the **current** stack and on the **new** stack from the same data
- [ ] Compare with `ogrinfo -al -so` on both: layer names, feature counts, field names, field types, SRIDs, geometry types
- [ ] Confirm the layer naming convention still holds — `Ogr::Postgres.get_feature_name` produces `WDPA_poly_MmmYYYY` / `WDPA_point_MmmYYYY` / source layer, and downstream users depend on those exact names
- [ ] Confirm multipolygon / multipoint casting is preserved (`cast_geom_to_multi` in `Download::Generators::Gdb`)
- [ ] Confirm the `source` layer is present and populated

### Functional

- [ ] Open both `.gdb` files in **ArcGIS** and confirm they behave identically
- [ ] Open both in **QGIS**
- [ ] Test a country-level download, a site-level download, and a full WDPA + WDOECM download
- [ ] Test the shapefile and CSV generators too — they share `Ogr::Postgres.export`

### Sign-off

- [ ] **Data team sign-off required** before this is called safe. Agree the acceptance criteria with them *before* starting the work, not after
- [ ] Record what was compared and by whom

---

## Dockerfile impact

Once done, the image build simplifies to:

```dockerfile
RUN apt-get install -y gdal-bin libgdal-dev libgeos-dev libproj-dev proj-data zip
```

Deleted:
- The `wget` of `gdal-2.2.3.tar.gz` and its `./configure` with ~40 flags
- The `wget` of `FileGDB_API-RHEL7-64gcc83.tar.gz` and the `/usr/local` copies
- `python-gdal` (Python 2 package — does not exist on modern Ubuntu anyway)

See [11](./11-deploy-and-devops.md) for the full production Dockerfile scope.

---

## Risks

| Risk | Mitigation |
|---|---|
| `OpenFileGDB` write output differs subtly from `FileGDB` in a way downstream users notice | The comparison checklist above; data-team sign-off before release |
| GDAL 3.8 changes behaviour vs 2.2.3 beyond the driver (field truncation, SRID handling) | Compare shapefile and CSV outputs too, not just `.gdb` |
| `ogrinfo -json` output shape differs across GDAL versions | Pin behaviour to the version in the image; the image is the contract now |
| Work lands late and blocks dockerization | **Start this before [11](./11-deploy-and-devops.md)** — it is on the critical path |

---

## Exit criteria

- `OpenFileGDB` driver in use; no ESRI SDK anywhere in the build
- Distro GDAL 3.8 — no source build
- `gdal` gem removed from the Gemfile; `Ogr::Info` reimplemented on `ogrinfo`
- `connection_config` replaced
- Output comparison completed for `.gdb`, shapefile and CSV
- **Data team sign-off recorded**
