# ESRI Field Name Migration Note

After ESRI services are updated to use `site_id` and `site_pid` (instead of `wdpaid` and `wdpa_pid`), update the following files:

## Files to Update

1. **`app/javascript/components/map/helpers/request-helpers.js`** (line 40)
   - Change `outFields=wdpaid,wdpa_pid` → `outFields=site_id,site_pid`
   - Remove commented line

2. **`app/models/protected_area.rb`** (line 271)
   - Change `where=wdpaid` → `where=site_id` in `arcgis_query_string`
   - Remove commented lines

3. **`app/models/protected_area.rb`** (line 278)
   - Change `where=wdpaid` → `where=site_id` in `extent_url`
   - Remove commented lines

4. **`app/helpers/map_helper.rb`** (line 156)
   - Change `where=wdpaid` → `where=site_id` in `site_ids_where_query`
   - Remove commented line

5. **`app/javascript/components/map/mixins/mixin-pa-popup.js`** (lines 100-102)
   - Change `pa.wdpaid` → `pa.site_id`
   - Change `pa.wdpa_pid` → `pa.site_pid`
   - Remove mapping comments

