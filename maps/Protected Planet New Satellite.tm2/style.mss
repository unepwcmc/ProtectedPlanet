Map {
  buffer-size:256;
  background-color: transparent;
}

#mapbox_satellite_full,
#mapbox_satellite_watermask  {
  raster-opacity: 1;
}

// Language
@name: '[name]';

/* set up font sets for various weights and styles */
@sans_lt:           "Open Sans Regular","Arial Unicode MS Regular";
@sans_lt_italic:    "Open Sans Italic","Arial Unicode MS Regular";
@sans:              "Open Sans Semibold","Arial Unicode MS Regular";
@sans_bold:         "Open Sans Bold","Arial Unicode MS Regular";
@sans_italic:       "Open Sans Semibold Italic","Arial Unicode MS Regular";
@sans_bold_italic:  "Open Sans Bold Italic","Arial Unicode MS Regular";

/* ================================================================== */
/* LANDUSE & LANDCOVER COLORS
/* ================================================================== */

@land:              #E8E0D8;
@water:             #73B6E6;
@grass:             #E1EBB0;
@sand:              #F7ECD2;
@park:              #C8DF9F;
@cemetery:          #D5DCC2;
@wooded:            #3A6;
@industrial:        #DDDCDC;

@building:          darken(@land, 8);
@hospital:          #F2E3E1;
@school:            #F2EAB8;
@pitch:             #CAE6A9;
@sports:            @park;

@parking:           fadeout(@road_fill, 75%);

/* ================================================================== */
/* ROAD COLORS
/* ================================================================== */

/* For each class of road there are three color variables:
 * - line: for lower zoomlevels when the road is represented by a
 *         single solid line.
 * - case: for higher zoomlevels, this color is for the road's
 *         casing (outline).
 * - fill: for higher zoomlevels, this color is for the road's
 *         inner fill (inline).
 */

@road_fill:     #fff;

/* ================================================================== */
/* BOUNDARY COLORS
/* ================================================================== */

@admin_2:           #dcb;
@admin_3:           #cba;
@admin_4:           #cba;

/* ================================================================== */
/* LABEL COLORS
/* ================================================================== */

/* We set up a default halo color for places so you can edit them all
   at once or override each individually. */
@place_halo:        #000;
@place_text:        #fff;

@road_halo:         #000;
@road_text:         #dddddd;

/* Also used for other small places: hamlets, suburbs, localities */
@village_halo:      #777777;
@village_text:      @place_halo;

@transport_text:    #cbcbcb;


