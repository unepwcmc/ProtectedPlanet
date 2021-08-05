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
