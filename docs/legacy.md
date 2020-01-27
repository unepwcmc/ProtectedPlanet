# Legacy Protected Planet - REMOVED AFTER 2020 REFRESH

We've done our best to not break links for the old Protected Planet.

## Protected Areas

In the previous version of Protected Planet, Protected Areas were
handled via a `/sites/:slug` route. The slugs and routes for Protected
Areas in this version differ, and as such we have a
`LegacyProtectedArea` model that handles matching old slugs to WDPA IDs.

These slugs were exported from the old Protected Planet production
database with the following command:

```
COPY sites (id,slug) TO '/tmp/legacy_protected_areas.csv' DELIMITER ',' CSV HEADER;
```
