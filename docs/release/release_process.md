# ProtectedPlanet Monthly Release Process

> **Complete guide for the monthly data release process for ProtectedPlanet**

This document walks you through the step-by-step process of releasing new protected area data to ProtectedPlanet each month.

## 📚 Related Documentation

This guide is the first in a series of four documents:

1. **[Monthly Release Process](release_process.md)** (this document) - Simple guide for everyone: CSV files, git workflow, and overview
2. **[Release Data Imports](release_data_imports.md)** - Comprehensive guide to what data is imported during a release
3. **[Portal Release Runbook](portal_release_runbook.md)** - Simple guide for developers: commands and workflows to run releases
4. **[Release Orchestration](release_orchestration.md)** - Technical reference for developers: architecture and code details
5. **[Monthly Release Flowchart](https://miro.com/app/board/uXjVJiMRukg=/)** - A high-level overview of the monthly release process, showing responsibilities and trigger points across the DT and NC teams.

---

## Affected Sites

The monthly WDPCA Release updates data for the following websites:

- [Protected Planet](http://protectedplanet.net) - Main website (This repo)
- [Protected Planet API](http://api.protectedplanet.net) - Public API ([repo](https://github.com/unepwcmc/protectedplanet-api))PAME data CSV (not always provided)

---

## Add the CSVs

### Step 1: Collect the CSV Files (As of 24Nov2025 Data for this will be moved to DB tables after stats server can feed in calculated results onto ProtectedPlanet DB)

You will receive CSV files from the WDPA team in the `#protectedplanet` Slack channel. Look for the pinned release thread where all files are shared.

**Files you may receive:**
- Global monthly statistics CSV
- National monthly statistics CSV (needs to be split - see below)
- PAME data CSV (most likly updated monthly/provided)
- Green list sites CSV (not always provided)
- Overseas Territories CSV (not always provided)

### Step 2: Transform and Add the CSV Files

All CSV files need to be placed in the `<project-root>/lib/data/seeds` directory with specific names and formats.

#### How to Transform Each File

**1. National Statistics CSV** - This file needs to be split into TWO files:

   - **File 1**: `pame_country_statistics_<YYYY-MM>-01.csv`
     - Keep only the ISO3 column and all columns that start with `pame_`
     - Example: On 07/11/2023, this resulted in 5 columns total
   
   - **File 2**: `country_statistics_<YYYY-MM>-01.csv`
     - Keep ALL columns EXCEPT the `pame_` columns
     - Example: On 07/11/2023, this resulted in 15 columns total

**2. Global Statistics CSV** - Simple rename:
   - Rename `PP_Global_Monthly_Stats_<MM-YY>.csv` → `global_statistics_<YYYY-MM>-01.csv`

**3. Green List CSV** - Simple rename:
   - Rename `Green List Sites Report - <M> <Y>` → `green_list_sites_<YYYY-MM>-01.csv`

**4. PAME Data CSV** - Simple rename:
   - Rename `PAME_data_<Y>_<M>.csv` → `pame_data_<YYYY-MM>-01.csv`

> **Note**: You only need to process files that were provided for the current month. If a file wasn't provided (like Green List or PAME), skip it - the system will use the last available version.

#### Step 3: Check CSV Files for Errors

Before committing, carefully check each CSV file for common issues:

**Encoding Issues:**
- ✅ All CSVs must be in **UTF-8** format
- ✅ Country statistics must be **UTF-8 without BOM** (Byte Order Mark)
- ❌ ANSI encoding will cause problems

**Format Issues:**
- Check that numbers use decimal points (`.`) not commas (`,`)
- Verify column headers match expected format (case-sensitive: `value` not `Value`)
- Ensure no empty columns exist
- Verify NULL values are shown as `-` not `0`

**Data Quality Issues:**
- Percentages should not exceed 100%
- Compare with previous month's file using diff tools like [WinMerge](https://winmerge.org/downloads/?lang=en) or [CSV-diff](https://pypi.org/project/csv-diff/)

**Common Problems Found in Past Releases:**
- Aug 2024: PAME data was in ANSI instead of UTF-8
- Nov 2023: Decimal delimiters were commas instead of points
- July 2024: Header was `Value` instead of `value`
- Dec 2023: Empty column L between rows L2-L64
- Jan 2024: Percentages over 100% (e.g., 100.25, 100.73)
- April/May 2025: PAME data had empty column P (should have exactly 15 columns)

**If you find errors:**
1. Document what you found
2. Report to the WDPA team in the `#protectedplanet` Slack channel
3. Note any manual fixes you had to make

**File Management:**
- Delete old CSV files from previous months (keep only a few of the latest versions)
- For files that aren't updated monthly (PAME, Green List, etc.), keep the latest version even if it's from an earlier month

### Step 4: Update PDFs (Optional)

If you received a new version of the WDPA Manual PDF:

1. Replace the files in `lib/data/documents/` for each language:
   - `ar/` - Arabic
   - `en/` - English
   - `es/` - Spanish
   - `fr/` - French
   - `ru/` - Russian

2. **Important**: Include Arabic and Russian manuals even if they're older versions

---

## Trigger the Database Release

### Before You Start

⚠️ **Critical Check**: Before triggering the database release, verify that all draft records have been approved in the [Data Management Portal](https://pp-data-management-portal.org/en/wdpa/data-management?recordsType=draft&sorting-_-BATCH_UPLOAD.id=descending&sorting-_-SITE_ID=ascending).

This ensures that all latest approved data will be included in the release.

### How to Run the Release

**To run the database release, follow the step-by-step instructions in the [Portal Release Runbook](portal_release_runbook.md).**

The runbook will guide you through:
- Running the release command
- Checking that everything worked correctly
- What to do if something goes wrong

---

## ✅ Release Complete

> **🎉 Once the release command completes successfully, the monthly release process is complete.**

You have successfully:
- ✅ Added CSV files to the repository
- ✅ Committed and merged changes
- ✅ Run the database release

The new data is now live on Protected Planet!

---

## Updating PP Maps and ESRI API

This step is usually handled by Osgur, but if he's unavailable, you can follow these steps:

### Overview

The map updates are separate from the main release process. The maps use Web Services that read from an Enterprise Geodatabase on a Linode server.

### Steps to Update Maps

1. **Replace data in Enterprise Geodatabase**
   - Updates the feature service automatically (it reads directly from this location)

2. **Recalculate Tile Cache**
   - Rebuilds the cached map tiles for faster rendering
   - This is what users see on the Protected Planet website maps

3. **Update Metadata**
   - Updates metadata for all layers in the Portal and Server

### How to Run the Update

Run the Python script from one of these locations:

- **Windows-Farm (rds)**: `G:\DATA\ScheduledTasks\Update_WDPA_WDOECM\WDPA_WDOECM_Enterprise_Update.py`
- **O-Drive**: `O:\f03_centre_initiatives\Protected_Planet_Initiative\Updating_WDPA_and_WD_OECM\Scripts\WDPA_WDOECM_Enterprise_Update.py`

**Log file location:**
`O:\f03_centre_initiatives\Protected_Planet_Initiative\Updating_WDPA_and_WD_OECM\Scripts\WDPA_WDOECM_Webservices_Updates.log`

### Verify the Update

After the script runs (takes a couple of hours), verify:

1. Check the log file for any errors
2. Confirm the WDPA WDOECM Updated date is correct on the [UNEP Data GIS Portal](https://data-gis.unep-wcmc.org/portal/home/item.html?id=1919c32890074ce5a589a1a99b48994b)

---

## 🆘 Getting Help

If you need assistance during the release process:

- **Running the release?** See [Portal Release Runbook](portal_release_runbook.md) for step-by-step instructions
- **Slack Channel**: Ask questions in `#protectedplanet`
- **Report Issues**: Create an issue in the [ProtectedPlanet repository](https://github.com/unepwcmc/ProtectedPlanet/issues)
