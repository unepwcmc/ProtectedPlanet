# What is Protected Areas and Protected Area Parcels
- Protected area can have more then one parcels each parcel might have different attributes and geospatial data. 
- There is a protected_areas table storing each PA, If the PA has multiple parcels then first parcel is saved to protected_areas as the representative
- There is a protected_areas_parcels table storing parcels of the protected_area (including the first parcel)
- So if A pa has multiple parcels then the first parcel is duplicately saved into protected_areas and protected_areas_parcels

# Import
- All data are in the import tables `standard_polygons` and `standard_points` you will now see the same wdpa_id in multiple rows if the PA has more then one parcel (wdpa_pid).
- See [attribute_importer.rb](/lib/modules/wdpa/protected_area_importer/attribute_importer.rb) to understand how protected_areas and protected_areas_parcels are imported

# Relations between protected_areas and protected_area_parcels
- foreign_key: 'wdpa_id', primary_key: 'wdpa_id' is used to link up the two tables
- See [protected_area.rb](/app/models/protected_area.rb) and [protected_area_parcel.rb](/app/models/protected_area_parcel.rb)

# Presenter for attributes
- See [protected_area_presenter.rb](/app/presenters/protected_area_presenter.rb) to understand how the parcels are then used in the frontend

# Caution
- When you do calculation for certain fields you need to consider if the PA has multiple parcels or not. Otherwise, your results will only take data of first parcel into consideration.
- An example can be found in the function reported_area of [protected_areas_helper.rb](/app/helpers/protected_areas_helper.rb)