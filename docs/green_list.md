# Green List Functionality

## Overview

The IUCN Green List of Protected and Conserved Areas is a global standard for protected areas. The Protected Planet application supports importing and displaying green list data for both protected areas and their associated parcels.

## Current Implementation (as of 29Sep2025)

**Key Behavior:** When a protected area is green-listed, ALL associated parcels automatically inherit the same green list status. This ensures consistency between the main protected area record and all its parcels.

**Future Considerations:** If parcel-specific green listing is needed (where only certain parcels are green-listed), only the (monthly release) importers and frontend Vue components need to be updated. The protectedplanet-api will work automatically since parcels already have green list columns in the database tables.

## Data Model

### Tables
- `green_list_statuses` - Status definitions (status, expiry_date)
- `protected_areas` - Main protected area records with green_list_status_id and green_list_url
- `protected_area_parcels` - Parcel records with green_list_status_id and green_list_url

### Relationships
- `ProtectedArea` belongs_to `GreenListStatus`
- `ProtectedAreaParcel` belongs_to `GreenListStatus`

## Import Process

### Data Sources
CSV files in `lib/data/seeds/green_list_sites_*.csv` with format:
```csv
site_id,status,expiry_date,url
17231,Green Listed,27-10-2023,"https://iucngreenlist.org/sites/Ajloun-Forest-Reserve"
```

### Importers
- **Portal Importer**: `Wdpa::Portal::Importers::GreenList` - imports to staging tables
- **Live Importer**: `Wdpa::GreenListImporter` - imports to live tables

Both importers update both `protected_areas` and `protected_area_parcels` tables to maintain consistency.

### Future Parcel-Specific Green Listing
If needed, only these components require updates:
- **Importers**: Add site_pid support in CSV processing
- **Frontend Vue**: Update UI to handle parcel-specific status
- **API**: No changes needed (parcels already have green list columns)

## Usage

### Import Data
```ruby
# Portal importer (staging)
Wdpa::Portal::Importers::GreenList.import_to_staging(notifier: notifier)

# Live importer
Wdpa::GreenListImporter.import
```

### Query Data
```ruby
# Green listed areas
ProtectedArea.green_list_areas

# Green listed parcels
ProtectedAreaParcel.joins(:green_list_status)
```

## Related Documentation
- [Protected Area Parcels](protected_area_parcels.md)
- [WDPA Import Process](wdpa.md)
