// Highlights individual features based on osm_id.
// The ID must be transformed to match the unique IDs in the DB.
// Unique ID rules described in lib.sql.
@hilite: #f73;
#airport_label, #rail_station_label, #place_label,
#bridge, #road, #tunnel, #landuse_overlay, #building,
#barrier_line, #aeroway, #water, #waterway, #landuse {
  ::mb_hilite[osm_id=0] {
    comp-op: hard-light;
    ['mapnik::geometry_type'=1][osm_id<0] {
      marker-width: 30;
      marker-line-color: darken(@hilite,20);
      marker-line-width: 4;
      marker-fill: @hilite;
      marker-allow-overlap: true;
      marker-ignore-placement: true;
    }
    ['mapnik::geometry_type'=2] {
      a/line-color: darken(@hilite,20);
      a/line-width: 13;
      a/line-cap: round;
      a/line-join: round;
      b/line-color: @hilite;
      b/line-width: 10;
      b/line-cap: round;
      b/line-join: round;
    }
    ['mapnik::geometry_type'=3] {
      polygon-fill: @hilite;
      polygon-comp-op: hard-light;
      line-color: darken(@hilite,20);
      line-width: 1.5;
      line-cap: round;
      line-join: round;
    }
  }
}
