### 4.11.9
Chore: September 2025 WDPA Release
  - update constants.rb
  - add September CSVs: country_statistics, global_statistics, pame_country, pame_data CSV.

### 4.11.8
- Chore: August 2025 WDPA Release
  - update constants.rb
  - add August CSVs: country_statistics, global_statistics, pame_country, pame_data
  - correct country_stats CSV because the space characters have been replaced by 0 in the column nr_version and nr_report of CSV. NC has been notified of the issue to avoid it happens again next month.

### 4.11.7
- Chore: July 2025 WDPA Release
  - update constants.rb
  - add July CSVs: country_statistics, global_statistics, pame_country, pame_data
  - edit extra line at the end of `country_stats` CSV and extra character at the end of `global_statistics` CSV

### 4.11.6
- Update PAME CSV to avoid issue caused by 34 duplicated `evaluation_id` and the wdpa_id = `5.56+e8` (556000000) in 389 records which is not a correct wdpa_id value

### 4.11.5
- Update PAME CSV to avoid issue caused by 22 duplicated `evaluation_id` and `_` (underscore) in `wdpa_id` when ingesting the GD-PAME in the Step11 of the monthly workflow

### 4.11.4
- Chore: June 2025 WDPA Release
  - update constants.rb
  - add June CSVs: country_statistics, global_statistics, pame_country, pame_data
  - ~1700 new PAME records this month

### 4.11.3
- Fix: Catch the scenario that if a country i,e VAT has no PAs then it was returning all PAME list instead of empty list
- Chore: remove remove equity chart in equity page

### 4.11.2
- Chore: 
  - fix: updating the PAME stats CSV that was build with wrong selection of columns
  
### 4.11.1
- Chore: May 2025 WDPA Release
  - update constants.rb
  - add May CSVs: country_statistics, global_statistics, pame_country, pame_data
  - PAME data had the "P" column as empty column which has to be deleted to avoid any issue during the deployment
  
### 4.11.0
- feat: Update add parcels table
- feat: Display PA parcels to frontend
- feat: Update Wdpa::ProtectedAreaImporter::AttributeImporter to import parcels
- chore: Add referer header added to the mapbox tile image request

### 4.10.23
- Chore: April 2025 WDPA Release
  - update constants.rb
  - add April CSVs: country_statistics, global_statistics, pame_country, pame_data (1403 new rows)
  - PAME data has a colum P empty that has to be deleted to avoid any issue during the deploy
  
### 4.10.22
- Chore: Mar 2025 WDPA Release
  - update constants.rb
  - add March CSVs: country_statistics, global_statistics, pame_country, pame_data

### 4.10.21
- Chore: Feb 2025 WDPA Release
  - update constants.rb
  - add February CSVs: country_statistics, global_statistics, pame_country, pame_data

### 4.10.20
- Chore: Jan 2025 WDPA Release
  - update constants.rb
  - add December CSVs: country_statistics, global_statistics, pame_country, pame_data

### 4.10.19
- Chore: Dec 2024 WDPA Release
  - update constants.rb
  - add December CSVs: country_statistics, global_statistics, pame_country, pame_data
  - delete all the old / previous CSVs (before November 2024)

### 4.10.18
- Chore: Nov 2024 WDPA Release (b)
  - edit November CSVs: country_statistics, global_statistics, pame_country to make it UTF8 compliand (without BOM)
  causing the error Error creating record for : unknown attribute 'iso3' for CountryStatistic. when we import National Stats
  
### 4.10.17
- Chore: Nov 2024 WDPA Release
  - update constants.rb
  - add November CSVs: country_statistics, global_statistics, pame_country, pame_data
  - the statistics have been calculated using new basemap
  
### 4.10.16
- Chore: Oct 2024 WDPA Update Statistics
  - add Updated October CSVs: country_statistics, global_statistics, pame_country

### 4.10.15
- Chore: Oct 2024 WDPA Release
  - update constants.rb
  - add October CSVs: country_statistics, global_statistics, pame_country, pame_data
  
### 4.10.14
- Chore: Sep 2024 WDPA Release
  - update constants.rb
  - add September CSVs: country_statistics, global_statistics, pame_country, pame_data
  
### 4.10.13
  - fix the issue with duplicated "evaluation_id" in PAME data CSV
  
### 4.10.12
  - fix the issue with PAME data CSV sent with ANSI encoding rather than UTF8-BOM expected

### 4.10.11
- Chore: Aug 2024 WDPA Release
  - update constants.rb
  - add August CSVs: country_statistics, global_statistics, pame_country, pame_data
  - many changes happen in the stats due to many updates by PP NC team and upgrade in the methodology
  
  ### 4.10.10
- Chore: Jul 2024 WDPA Release
  - update constants.rb
  - add July CSVs: country_statistics, global_statistics, pame_country, pame_data

### 4.10.9
- Chore: Jun 2024 WDPA Release
  - update constants.rb
  - add June CSVs: country_statistics, global_statistics, pame_country, pame_data
  - replace Global Map PDF
  
### 4.10.8
- Chore: May 2024 WDPA Release
  - update constants.rb
  - add March CSVs: country_statistics, global_statistics, pame_country, pame_data
  - replace Global Map PDF by a lower resolution (JPEG2000)
  
### 4.10.7
- Chore: April 2024 WDPA Release
  - update constants.rb
  - add March CSVs: country_statistics, global_statistics, pame_country, pame_data
  - replace Global Map PDF
  
### 4.10.6
- Chore: March 2024 WDPA Release
  - update constants.rb
  - add March CSVs: country_statistics, global_statistics, pame_country, pame_data
  - replace Global Map PDF
  - delete all the old / previous CSVs (before February 2024)

### 4.10.5
- update: Global Stats CSV of Feb 2024

### 4.10.4
- Chore: February 2024 WDPA Release
  - February statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced

### 4.10.3
- Fix: remove wrong check for get_jurisdictions

### 4.10.2
- Fix: Differentiate state-overview for country and Region Page
- Fix: Put back Other category to National Designations

### 4.10.1
- Feature: Add Tooltip containing number of national designations only for WDPA and OECM to country page - statistics area
- Feature: Designations section in country page
  - Add Other category
  - For national designations category decoupled national and other categories
- Chore: Add documentations for mac user setup
- Chore: Update docker md to

### 4.9.14
- Chore: January 2024 WDPA Release
  - January statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `overseas_territories` updated
  - `constants.rb` updated
  - Map PDF replaced

### 4.9.13
- Chore: December 2023 WDPA Release
  - December statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced

### 4.9.12
- Chore: November 2023 WDPA Release
  - November statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced

### 4.9.11
- Chore: October 2023 WDPA Release
  - October statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced

### 4.9.10
- Chore: September 2023 WDPA Release
  - September statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced

### 4.9.9
- Chore: August 2023 WDPA Release
  - August statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced

### 4.9.8
- Update country names
- remove parent-child relationship between IOT and GBR
- use MUS url for IOT bbox, because IOT no longer being returned by WCMC API

### 4.9.7
- Chore: July 2023 WDPA Release
  - July statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced

### 4.9.6
- Chore: June 2023 WDPA Release
  - June statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced

### 4.9.5
- bug fix: PAME evaluation counts and overseas territories

### 4.9.4
- Chore: May 2023 WDPA Release
  - May statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced
- Fix map zoom for territories crossing the international date line
- Add missing protected area attributes to the database (via importer) - `marine_type`, `verif` and `parent_iso3`

### 4.9.3
- Fix: Cap percentage to 100.0 for marine protected area if it goes over 100%

### 4.9.2
- Chore: Apr 2023 WDPA Release
  - Apr statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced
- Fix .gdb download - use MultiPoints instead of Points in the generated dataset
- Remove some content of the marine thematic area page from CMS for dynamic statistics in text
- small button fix
### 4.9.1
- Update pdf with new map that excludes Crimea PAs
### 4.9.0
- Added Docker
- Update Wdpa::GeometryRatioCalculator to add additional geom count fields to CountryStatistics, which will be returned by API

### 4.8.29
- Chore: Mar 2023 WDPA Release
  - Mar statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced

### 4.8.28
- Chore: Feb 2023 WDPA Release
  - Feb statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced
  - Update map disclaimer

### 4.8.27
- Revert geojson simplification methods for mapbox

### 4.8.26
- Chore: Jan 2023 WDPA Release
  - Jan statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced

### 4.8.25
- Chore: Dec 2022 WDPA Release
  - Dec statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced

### 4.8.24
- Chore: Nov 2022 WDPA Release
  - Nov statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced
- Feature: Add filter for Green List candidate sites on search page
- Bug fix: Fix size of percentage boxes (e.g., on country pages)
- Bug fix: Fix missing thumbnail images

### 4.8.23
- Bug fix: Google search results
  - Remove bingbot line in robots.txt to enable Google indexing

### 4.8.22
- Bug fix: Google Analytics Event tracking
  - Add in missing ids to enable GA event tracking
  - Add tracking to Download global statistics link
  - Add tracking to Region/Country page stats tabs

### 4.8.21
- Chore: Oct 2022 WDPA Release
  - Oct statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced

### 4.8.20
- Chore: Sep 2022 WDPA Release
  - Sep statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced

### 4.8.19
- Chore: Aug 2022 WDPA Release
  - Aug statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - `constants.rb` updated
  - Map PDF replaced

### 4.8.18
- bug fix: use constants to choose bucket for user downloads, use latest bucket for releases

### 4.8.17
- Chore: July 2022 WDPA Release
  - July statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - Constants updated
  - Map PDF replaced

### 4.8.16
- fixed url for country boundaries

### 4.8.15
- Styled download global statistics link on homepage

### 4.8.14
- Added global statistics download
- Fixed PAME file downloads
- Limited map zoom on global WMS layer
- Updated external API calls to work after API changes
- Stopped trying to load geom into memory and use extent to determine whether PA is point or polygon
- Fixed region links on search results
- Minor text changes

### 4.8.13
- Removed MPA download option
- Changed Mapbox basemap to most recent version
- Hid PA growth charts from country pages
- Changed PA text to include "and other effective area-based conservation measures"
 
### 4.8.12
- Removed Western Sahara flag
- Fixed French Guiana typo
- Added SAR China to Hong Kong and Macau

### 4.8.11

- Chore: June 2022 WDPA Release
  - June statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - Constants updated
  - Map PDF replaced

### 4.8.10

- Chore: May 2022 WDPA Release
  - May statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - Constants updated
  - Map PDF replaced
- Fix: Remove Canada's data restriction notice

### 4.8.9
- Revert bug 'fix', downloads now look in the most recent bucket again.

### 4.8.8

- Chore: April 2022 WDPA Release
  - April statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - Constants updated
  - Map PDF replaced

### 4.8.7

- Use date constants to select S3 bucket for data download

### 4.8.6

- Chore: March 2022 WDPA Release
  - March statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - Constants updated
  - Map PDF replaced

### 4.8.5

- Chore: February 2022 WDPA Release
  - February statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - Constants updated
  - Map PDF replaced

### 4.8.4

- Chore: January 2022 WDPA Release
  - January statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - Constants updated
  - Map PDF replaced

### 4.8.3

- Chore: December WDPA Release
  - December statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data`
  - Constant updated

### 4.8.2

- Chore: November WDPA Release
  - November statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country`, `pame_data` and also `green_list_sites`.
  - Constant updated

- Chore: Content update in `config/locales/country/en.yml`
  - Benin's restricted data notice has been removed

### 4.8.1

- Chore: October WDPA Release
  - October statistics CSVs added: `country_statistics`, `global_statistics`, `pame_country` and `pame_data`
  - Map PDF
  - Constant updated

- Chore: Content update in `config/locales/country/en.yml`
  - Turkey and Benin now have restricted data notices
  - Finland's restricted data notice has been removed
  - The number of Protected Areas in Estonia's resricted data message is now 3589, rather than 3222

### 4.8.0

- Chore: September 2021 WDPA release
  - September statistics: `country_statistics`, `global_statistics`, `pame_country` and `pame_data`
  - Map PDF
  - Update constant

- Feat: MPA guide component
  - `_mpa-guide.html.erb` partial added
  - Corresponding styles added to `components/_cta.scss`

- Fix: Commercial download text
  - Text updated
  - Styling changes made to download modal

### 4.7.0

- Chore: August 2021 WDPA release
  - National and global monthly statistics
  - Green List sites
  - GD PAME data
  - Update global map

- Refactor: Change format of CSV seeds:
  - `pame_country_stats.csv -> pame_country_statistics_<YYYY-MM-DD>.csv`
  - `country_stats.csv -> country_statistics_<YYYY-MM-DD>.csv`
  - `global_stats.csv -> global_statistics_<YYYY-MM-DD>.csv`
  - `green_list_sites.csv -> green_list_sites_<YYYY-MM-DD>.csv`

- Refactor: Update relevant importers with logic to select latest CSVs automatically

- Fix: stats cards
- Fix: non-rendering sources by requiring >=1 sources
- Fix: Country#show: Disable download when no WDPAs
- Fix: Replace #zero? with simple equality operator

### 4.6.5

- Update global monthly stats for July 2021

### 4.6.4

- July 2021 WDPA release
  - National and global monthly statistics
  - GD PAME data
  - Update global map

### 4.6.3

- June 2021 WDPA release
  - National and global monthly statistics
  - Green List sites
  - GD PAME data
- Fixed filenames being too long for downloads of all areas via the search page
- Add disclaimer on certain country pages for data sourced from restricted PAs

### 4.6.2

- Hotfix for the search areas page downloads - allow searches with more than 10000 hits
to be downloaded in full.

### 4.6.1

May release continued - late-arriving global and national monthly stats

### 4.6.0

- Update the jurisdictions.csv seed file to include the missing jurisdiction
- Fix flags not appearing for the country pages
- Fix CTA content being wiped after monthly imports
- Improve accuracy of the search (now ignoring diacritics)
- Fix the equity page and conditionally render links to the associated PA for the dropdown
- Fix the map thumbnails
- May release of the WDPA:
  - New GL sites
  - GD PAME data

### 4.5.4

* Add custom validator for resource page links and fix resource page links/attachments not appearing on resource pages

### 4.5.3

* Apr 2021 release (new PAME data, global and national monthly statistics)
* Fixed High seas bar chart legend key text
* Latest WDPA release update date now present on home page
* Routes re-organised
* Fix country pages for territories that lack a PAME statistic (e.g. Nauru)

### 4.5.2

* Mar 2021 release (new GL data, PAME data, public map, global and national monthly statistics)

### 4.5.1

* Duplicate search filters (in the Designations filter option of the PA search) have been removed.
* Social media previews have been fixed for Facebook and LinkedIn - partial fix for Twitter, but
  only for articles without images in the content.

### 4.5.0

Assorted fixes:
* PAME download names have been standardised, as well as shapefile filenames, following a convention: see
  [this](https://unep-wcmc.codebasehq.com/projects/protected-planet-support-and-maintenance/tickets/188#update-65893225)
  for more details
* Other changes to downloads: single GDB file implemented, sources exported into same GDB file
* Download citations now reflect last WDPA release data, as well as differing name depending on page
* Add Capistrano task to clear the cache during deployment to avoid missing styles

### 4.4.1

* Feb 2021 release (new GL data, PAME data, public map, global and national monthly statistics)

### 4.4.0

Assorted fixes:
- Update country and region extend URLs which are now sourced from the ArcGIS layer directly
- Links for the news article cards on the homepage have been fixed
- RTL languages are now represented correctly on maps

### 4.3.0

* Tabs on relevant thematic area pages (e.g. PAME) are now directly linked to,
enabling them to be shared.
* Added global, national statistics for January release along with PAME data.

### 4.2.0

* Added tabs for country and region pages which feature OECMs, allowing users to
switch between WDPA-only and WDPA and OECM statistics.

### 4.1.3

* Added country (with OECM), PAME and GD PAME statistics for December.

### 4.1.2

* Rake task created to only reindex the CMS in Elasticsearch
* Active Storage tables now transfer over upon import
* Homepage statistics in cards now aligned with marine page statistics

### 4.1.1

November release
* Updated with November statistics (GD PAME, Global Monthly, National Monthly and GL)

### 4.1.0

**New Feature**

* Add World Heritage Outlook website link to PA page

**Amendments**

* Increase PA page map's height

**Bug fixes**

* Fix links green arrow icons not showing

### 4.0.1

* Fixed suggested sites not being displayed for sites with ABNJ status
* Custom 500 page created
* IUCN link now shown for GL sites if present

### 4.0.0

* Refresh! Major restyling of all components

### 3.2.16

* Add country, pame_country and marine stats (WDPA September 2020 release).

### 3.2.15

* Added assorted statistics for August 2020 release.
* Shapefile README included.

### 3.2.14

* Allow to split data into multiple shapefiles

### 3.2.13

* Add country, pame_country and marine stats (WDPA June 2020 release).

### 3.2.12

* Fix PAME evaluations count mismatch between country page and API
* Fix data download bug sometimes downloading incorrect files

### 3.2.11

* Add country, pame_country and marine stats (WDPA May 2020 release).
* Fix coverage percentage statistics

### 3.2.10

* Add country, pame_country and marine stats (WDPA April 2020 release).

### 3.2.9

* Add country, pame_country and marine stats (WDPA March 2020 release).

### 3.2.8

* Calculate and populate assessments and assessed_pas fields for PameStatisic during import

### 3.2.7

* Add country, pame_country and marine stats (WDPA February 2020 release).

### 3.2.6

* Add country, pame_country and marine stats (WDPA January 2020 release).
* Update rack, nokogiri and rubyzip gems

### 3.2.5

* Add download tracking for links in CMS (e.g. OECM downloads)

### 3.2.4

* Add country, pame_country and marine stats (WDPA December 2019 release).

### 3.2.3

* Update reference on Target 11 Dashboard to DOPA - again

### 3.2.2

* Update reference on Target 11 Dashboard to DOPA

### 3.2.1

* Add country, pame_country and marine stats (WDPA November 2019 release).

### 3.2.0

**New Feature**

* Add Aichi 11 Target Dashboard

**Amendments**

* Regional statistics calculated using a view

### 3.1.0

**Bug fixes**

* Fix wdpa release import after aws gem upgrade
* Fix over-100% coverage statistics
* Add country, pame_country and marine stats (WDPA October 2019 release).

### 3.0.0

* Upgrade to Rails 5.0.5
* Add webpacker 4.0.2
* Remove dependency on the protectedplanet-frontend repo and move styles in asset folder
* Add docker for local development

### 2.6.1

* Add country, pame_country and marine stats (WDPA September 2019 release).

### 2.6.0

* Add National Report stats to countries
* Update country_statistics csv structure to include National Report stats

### 2.5.3

* Add country, pame_country and marine stats (WDPA August 2019 release).

### 2.5.2

**Bug fixes**

* Fix PameImporter to manage restricted and hidden evaluations correctly
* Fix CSV file to have iso codes instead of country names

### 2.5.1

* Add new url functionality for the PAME importer and fix the restricted PAME Evaluations.

### 2.5.0

* Add and populate boolean column for countries to flag the ACP (BIOPAMA) related ones

### 2.4.7

* Update the PAME importer for restricted PAME Evaluations with restricted Protected Areas flag.

### 2.4.6

* Add country, pame_country and marine stats (WDPA July 2019 release).

### 2.4.5

* Update the text and variables on the Marine page to prevent data becomming out of date.
* Manually add the Mapbox logo to the maps
* Hide commitments and pledges data download link on the Marine page

### 2.4.4

* Add country, pame_country and marine stats (WDPA May 2019 release).

### 2.4.3

* Update the PAME importer to use the latest monthly CSV (May 2019 release).
* Move Home Carousel slide model under cms namespace to prevent contents disappearing after release.

### 2.4.2

* Update the PAME importer to use the latest monthly CSV with additional PAME Evaluation information.
* Add pame source model.

### 2.4.1

* Add a warning message to country pages that have restricted Protected Areas

### 2.4.0

* Show all blog post (including grandchildren .etc) on the blog page
* Change the zip filename for the protected area search results to be more reader friendly
* Add the ability for a country to have many story maps

### 2.3.0

* Add blog
* Remove kml format download

### 2.2.0

* Link DOIs to preferred resolver (reference links)
* Add carousel with slides on the home page

### 2.1.7

* Add PAME importer to list of monthly importers

### 2.1.6

* Update Green List sites

### 2.1.5

* Use WDPA ID instead of slug for the show pages to prevent issue with protected areas with same name

### 2.1.4

* Rename PAME statistics field from :method to :methodology to avoid reserved word clashes

### 2.1.3

* Removes `resp_email` from download generator to fix bug when download fails to generate

### 2.1.2

**PAME stats**

* Round percentage to 2 places

**Countries**

* Change Swaziland name to Eswatini, the Kingdom of in seed file and db

### 2.1.1

**PAME stats**

* Show 'Not Reported' instead of year when the year for a PAME evaluation is 0

### 2.1.0

**PAME stats**

* Adds PAME statistics to Country and Protected Area page
* Adds importer for PAME statistics
* Adds support for PAME Evaluations
* Adds importer for PAME Evaluations

### 2.0.1

**Search results:**

* Fixed search results to correctly display the PA coverage total percentage (land and marine)
