// *********************************************************************
// MAPBOX STREETS
// *********************************************************************

// =====================================================================
// FONTS
// =====================================================================

// Language
@name: '[name]';

// set up font sets for various weights and styles
@sans_lt:           "Open Sans Regular","Arial Unicode MS Regular";
@sans_lt_italic:    "Open Sans Italic","Arial Unicode MS Regular";
@sans:              "Open Sans Semibold","Arial Unicode MS Regular";
@sans_bold:         "Open Sans Bold","Arial Unicode MS Regular";
@sans_italic:       "Open Sans Semibold Italic","Arial Unicode MS Regular";
@sans_bold_italic:  "Open Sans Bold Italic","Arial Unicode MS Regular";

// =====================================================================
// LANDUSE & LANDCOVER COLORS
// =====================================================================

@land:              #EFEFE5;
@water:             #B7D3DB;
@grass:             #E1EBB0;
@sand:              #F7ECD2;
@rock:              #D8D7D5;
@park:              #C8DF9F;
@cemetery:          #D5DCC2;
@wood:              #E4E3D0;
@industrial:        #DDDCDC;
@agriculture:       #EAE0D0;
@snow:              #EDE5DD;
@crop:              #EBE9DA;
@building:          darken(@land, 8);
@hospital:          #F2E3E1;
@school:            #F2EAB8;
@pitch:             #CAE6A9;
@sports:            @park;

@parking:           fadeout(@road_fill, 75%);

// =====================================================================
// ROAD COLORS
// =====================================================================

// For each class of road there are three color variables:
// - line: for lower zoomlevels when the road is represented by a
//         single solid line.
// - case: for higher zoomlevels, this color is for the road's
//         casing (outline).
// - fill: for higher zoomlevels, this color is for the road's
//         inner fill (inline).

@motorway_line:     #fff;
@motorway_fill:     #fff;
@motorway_case:     #000;

@main_line:     #fff;
@main_fill:     #fff;
@main_case:     #000;

@road_line:     #fff;
@road_fill:     #fff;
@road_case:     #000;

@pedestrian_line:   #fff;
@pedestrian_fill:   @pedestrian_line;
@pedestrian_case:   @road_case;

@path_line:     #fff;
@path_fill:     #fff;
@path_case:     @land;

@rail_line:     #aaa;
@rail_fill:     #fff;
@rail_case:     @land;

@bridge_case:   #999;

@aeroway:       lighten(@industrial,5);

// =====================================================================
// BOUNDARY COLORS
// =====================================================================

@admin_2:           #234;
@admin_3:           #345;
@admin_4:           #345;

// =====================================================================
// LABEL COLORS
// =====================================================================

// We set up a default halo color for places so you can edit them all
// at once or override each individually.
@place_halo:        #fff;

@country_text:      #999B9A;
@country_halo:      @place_halo;

@state_text:        #999B9A;
@state_halo:        @place_halo;

@city_text:         #999B9A;
@city_halo:         @place_halo;

@town_text:         #999B9A;
@town_halo:         @place_halo;

@poi_text:          #999B9A;  

@road_text:         #999B9A;
@road_halo:         #fff;

@other_text:        #999B9A;
@other_halo:        @place_halo;

@locality_text:     #999B9A;
@locality_halo:     @land;

// Also used for other small places: hamlets, suburbs, localities
@village_text:      #999B9A;
@village_halo:      @place_halo;

@transport_text:    #999B9A;

/**/