# What is Protected Areas and Protected Area Parcels
- Protected area can have more then one parcels each parcel might have different attributes and geospatial data. 
- There is a protected_areas table storing each PA, If the PA has multiple parcels then first parcel is saved to protected_areas as the representative
- There is a protected_areas_parcels table storing parcels of the protected_area (including the first parcel)
- So if A pa has multiple parcels then the first parcel is duplicately saved into protected_areas and protected_areas_parcels

# Green List Status
- As of 29Sep2025, green list status is maintained in both protected_areas and protected_area_parcels tables
- When a protected area is green-listed, ALL associated parcels inherit the same green list status
- This ensures consistency between the main protected area record and all its parcels
- Both tables have green_list_status_id and green_list_url columns
- See [Green List Documentation](green_list.md) for detailed information about the import process

# Import
## Portal Release Import
- When a portal release exists, data are sourced from portal materialized views: `portal_standard_polygons` and `portal_standard_points` (or their staging versions: `staging_portal_standard_polygons` and `staging_portal_standard_points`).
- The same site_id will appear in multiple rows if the PA has more than one parcel (site_pid).
- See [portal attribute importer](/lib/modules/wdpa/portal/importers/protected_area/attribute.rb) to understand how protected_areas and protected_areas_parcels are imported for portal releases.
- The system automatically selects the appropriate importer and views based on whether a portal release exists (see `Download::Config.has_successful_portal_release?`).

# Relations between protected_areas and protected_area_parcels
- foreign_key: 'site_id', primary_key: 'site_id' is used to link up the two tables
- See [protected_area.rb](/app/models/protected_area.rb) and [protected_area_parcel.rb](/app/models/protected_area_parcel.rb)

# Presenter for attributes
- See [protected_area_presenter.rb](/app/presenters/protected_area_presenter.rb) to understand how the parcels are then used in the frontend

# Caution
- When you do calculation for certain fields you need to consider if the PA has multiple parcels or not. Otherwise, your results will only take data of first parcel into consideration.
- An example can be found in the function reported_area of [protected_areas_helper.rb](/app/helpers/protected_areas_helper.rb)