// BG.MSS CONTENTS
// - Background
// - Land
// - Waterways, waterareas
// - Aeroways
// - Buildings
// - Barriers
// - Administrative Boundaries

Map { background-color: @land; }

// =====================================================================
// WATER AREAS
// =====================================================================

#water {
  polygon-fill: @water;
  polygon-gamma: 0.75;
}

// =====================================================================
// WATER WAYS
// =====================================================================

#waterway[zoom>=8][zoom<=11],
#waterway[class='river'][zoom>=12],
#waterway[class='canal'][zoom>=12] {
  line-color: @water;
  [zoom=8] { line-width: 0.1; }
  [zoom=9] { line-width: 0.2; }
  [zoom=10] { line-width: 0.4; }
  [zoom=11] { line-width: 0.6; }
  [zoom=12]{ line-width: 0.8; }
  [zoom=13]{ line-width: 1; }
  [zoom>12]{
    line-cap: round;
    line-join: round;
  }
  [zoom=14]{ line-width: 1.5; }
  [zoom=15]{ line-width: 2; }
  [zoom=16]{ line-width: 3; }
  [zoom=17]{ line-width: 4; }
  [zoom=18]{ line-width: 5; }
  [zoom=19]{ line-width: 6; }
  [zoom>19]{ line-width: 7; }
}

#waterway[class='stream'][zoom>=13],
#waterway[class='stream_intermittent'][zoom>=13] {
  line-color: @water;
  [zoom=13]{ line-width: 0.2; }
  [zoom=14]{ line-width: 0.4; }
  [zoom=15]{ line-width: 0.6; }
  [zoom=16]{ line-width: 0.8; }
  [zoom=17]{ line-width: 1; }
  [zoom=18]{ line-width: 1.5; }
  [zoom=19]{ line-width: 2; }
  [zoom>19]{ line-width: 2.5; }
  [class='stream_intermittent'] {
    [zoom>=13] { line-dasharray:20,3,2,3,2,3,2,3; }
    [zoom>=15] { line-dasharray:30,6,4,6,4,6,4,6; }
    [zoom>=18] { line-dasharray:40,9,6,9,6,9,6,9; }
  }
}

#waterway[class='ditch'][zoom>=15],
#waterway[class='drain'][zoom>=15] {
  line-color: @water;
  [zoom=15]{ line-width: 0.1; }
  [zoom=16]{ line-width: 0.3; }
  [zoom=17]{ line-width: 0.5; }
  [zoom=18]{ line-width: 0.7; }
  [zoom=19]{ line-width: 1; }
  [zoom>19]{ line-width: 1.5; }
}

// =====================================================================
// LANDUSE
// =====================================================================

#landuse[zoom>=7] {
  [class='pitch'] {
    polygon-fill: @pitch;
    [zoom>14] {
      line-width:0.8;
      line-color:lighten(@pitch,8);
    }
    [zoom=16] { line-width:1; }
    [zoom=17] { line-width:1.2; }
    [zoom=18] { line-width:1.4; }
  }
  [class='school'] {
    polygon-fill: @school;
    polygon-opacity: 0.5;
  }
  [class='cemetery'] {
    polygon-fill: @cemetery;
  }
  [class='hospital'] {
    polygon-fill: @hospital;
  }
  [class='parking'] {
    polygon-fill: @parking;
  }
  [class='sand'] {
    polygon-fill: @sand;
    polygon-pattern-file: url(img/pattern/sand.png);
    polygon-pattern-alignment: global;
  }
  [class='rock'] {
    polygon-fill: @rock;
  }
  [class='industrial'] {
    polygon-fill: @industrial;
  }
  [class='agriculture'] {
    polygon-fill: @agriculture;
  }
  [class='glacier'],
  [class='piste'] {
    polygon-fill: @snow;
  }
}

#landuse_overlay[zoom>=12] {
  [class='wetland'] {
    polygon-pattern-opacity: 0.5;
    [zoom>=12] { polygon-pattern-file:url(img/pattern/wetland-12.png);}
    [zoom>=14] { polygon-pattern-file:url(img/pattern/wetland-14.png);}
    [zoom>=15] { polygon-pattern-file:url(img/pattern/wetland-15.png);}
    [zoom>=16] { polygon-pattern-file:url(img/pattern/wetland-16.png);}
    [zoom>=17] { polygon-pattern-file:url(img/pattern/wetland-17.png);}
    [zoom>=18] { polygon-pattern-file:url(img/pattern/wetland-18.png);}
  }
  [class='wetland_noveg'] {
    polygon-pattern-opacity: 0.5;
    [zoom>=12] { polygon-pattern-file:url(img/pattern/wetland-noveg-12.png);}
    [zoom>=14] { polygon-pattern-file:url(img/pattern/wetland-noveg-13.png);}
    [zoom>=16] { polygon-pattern-file:url(img/pattern/wetland-noveg-14.png);}
    [zoom>=18] { polygon-pattern-file:url(img/pattern/wetland-noveg-15.png);}
  }
}


// =====================================================================
// AEROWAYS
// =====================================================================

// lines
#aeroway['mapnik::geometry_type'=2][zoom>9] {
  line-color:@aeroway;
  line-cap:butt;
  line-join:miter;
  [type='runway'] {
    [zoom=10]{ line-width:1; }
    [zoom=11]{ line-width:2; }
    [zoom=12]{ line-width:3; }
    [zoom=13]{ line-width:5; }
    [zoom=14]{ line-width:7; }
    [zoom=15]{ line-width:11; }
    [zoom=16]{ line-width:15; }
    [zoom=17]{ line-width:19; }
    [zoom>17]{ line-width:23; }
  }
  [type='taxiway'] {
    [zoom<13]{ line-width:0.2; }
    [zoom=13]{ line-width:1; }
    [zoom=14]{ line-width:1.5; }
    [zoom=15]{ line-width:2; }
    [zoom=16]{ line-width:3; }
    [zoom=17]{ line-width:4; }
    [zoom>17]{ line-width:5; }
  }
}

// polygons
#aeroway['mapnik::geometry_type'=3][zoom>=13] {
  polygon-fill: @aeroway;
  [type='apron'] {
    polygon-fill: @parking;
  }
}


// =====================================================================
// BUILDINGS
// =====================================================================

#building[zoom>12] {
  // We ease buildings in, making them less intense at lower zooms.
  // Outlines are added for the higher zoom levels only.
  [zoom=13] {  
    polygon-fill:lighten(@building,4);
  }
  [zoom=14] {
    polygon-fill:lighten(@building,2);
  }
  [zoom=15] {
    polygon-fill:lighten(@building,1);
    line-color:darken(@building,8);
    line-width:0.15;
  }
  [zoom>15] {
    polygon-fill:@building;
    line-color:darken(@building,12);
    line-width:0.3;
  }
}


// =====================================================================
// BARRIERS
// =====================================================================

#barrier_line[zoom>=17][class='gate'] {
  line-width:2.5;
  line-color:#aab;
}

#barrier_line[zoom>=17][class='fence'] {
  line-color:@building;
  [zoom=17] { line-width:0.6; }
  [zoom=18] { line-width:0.8; }
  [zoom>18] { line-width:1; }
}

#barrier_line[zoom>=16][class='hedge'] {
  line-width:2.4;
  line-color:darken(@park,20);
  [zoom=16] { line-width: 0.6; }
  [zoom=17] { line-width: 1.2; }
  [zoom=18] { line-width: 1.4; }
  [zoom>18] { line-width: 1.6; }
}

#barrier_line[zoom>=13][class='land'] {
  ['mapnik::geometry_type'=2][zoom>=14] {
    // These shouldn't be scaled based on pixel scaling
    line-color:@land;
    [zoom=14] { line-width: 0.75; }
    [zoom=15] { line-width: 1.5; }
    [zoom=16] { line-width: 3; }
    [zoom=17] { line-width: 6; }
    [zoom=18] { line-width: 12; }
    [zoom=19] { line-width: 24; }
    [zoom>19] { line-width: 48; }
  }
  ['mapnik::geometry_type'=3] {
    polygon-fill:@land;
  }
}

#barrier_line[zoom>=14][class='cliff'] {
  line-pattern-file: url(img/pattern/cliff-md.png);
  [zoom>=16] { line-pattern-file: url(img/pattern/cliff-lg.png); }
}


// =====================================================================
// ADMINISTRATIVE BOUNDARIES
// =====================================================================

#admin[zoom>=2] {
  ::lev2outline[admin_level=2][maritime=0] {
    opacity: 0.4;
    line-join: round;
    line-cap: round;
    line-color: #fff;
    [zoom>=2][zoom<=3] { line-width: 0.4 + 2; }
    [zoom>=4][zoom<=5] { line-width: 0.8 + 2; }
    [zoom>=6][zoom<=7] { line-width: 1.2 + 3; }
    [zoom>=8][zoom<=9] { line-width: 1.8 + 3; }
    [zoom>=10][zoom<=11] { line-width: 2.2 + 3; }
    [zoom>=12][zoom<=13] { line-width: 2.6 + 3; }
    [zoom>=14][zoom<=15] { line-width: 3.0 + 3; }
    [zoom>=16] { line-width: 4.0 + 3; }
  }
  ::lev2[admin_level=2] {
    opacity: 0.4;
    line-join: round;
    line-color: @admin_2;
    [maritime=1] {
      line-color: #026;
      line-opacity: 0.05;
    }
    [zoom>=2][zoom<=3] { line-width: 0.4; }
    [zoom>=4][zoom<=5] { line-width: 0.8; }
    [zoom>=6][zoom<=7] { line-width: 1.2; }
    [zoom>=8][zoom<=9] { line-width: 1.8; }
    [zoom>=10][zoom<=11] { line-width: 2.2; }
    [zoom>=12][zoom<=13] { line-width: 2.6; }
    [zoom>=14][zoom<=15] { line-width: 3.0; }
    [zoom>=16] { line-width: 4.0; }
    [disputed=1][zoom<=5] { line-dasharray: 4 , 3; }
    [disputed=1][zoom>=6][zoom<=7] { line-dasharray: 5 , 3; }
    [disputed=1][zoom>=8][zoom<=9] { line-dasharray: 7 , 4; }
    [disputed=1][zoom>=10][zoom<=11] { line-dasharray: 9 , 5; }
    [disputed=1][zoom>=12][zoom<=13] { line-dasharray: 11 , 6; }
    [disputed=1][zoom>=14][zoom<=15] { line-dasharray: 13 , 7; }
    [disputed=1][zoom>=16] { line-dasharray: 15 , 8; }
  }
  ::lev34outline[admin_level>=3][maritime=0] {
    opacity: 0.4;
    line-join: round;
    line-cap: round;
    line-color: #fff;
    line-opacity: 0.5;
    [zoom=5] { line-width: 0.4 + 2; }
    [zoom>=6][zoom<=7] { line-width: 0.8 + 2; }
    [zoom>=8][zoom<=9] { line-width: 1.2 + 2; }
    [zoom>=10][zoom<=11] { line-width: 1.6 + 2; }
    [zoom>=12][zoom<=13] { line-width: 2.0 + 2; }
    [zoom>=14][zoom<=15] { line-width: 2.4 + 2; }
    [zoom>=16] { line-width: 2.8 + 2; }
  }
  ::lev34[admin_level>=3] {
    [admin_level=3] {
      line-color: @admin_3;
      line-opacity: 0.75;
      line-dasharray: 12, 3;
    }
    [admin_level=4] {
      line-color: @admin_4;
      line-opacity: 0.25;
      line-dasharray: 10, 2;
    }
    [maritime=1] { line-opacity: 0.04; }
    [zoom>=2][zoom<=3] { line-width: 0.2; }
    [zoom>=4][zoom<=5] { line-width: 0.4; }
    [zoom>=6][zoom<=7] { line-width: 0.8; }
    [zoom>=8][zoom<=9] { line-width: 1.2; }
    [zoom>=10][zoom<=11] { line-width: 1.6; }
    [zoom>=12][zoom<=13] { line-width: 2.0; }
    [zoom>=14][zoom<=15] { line-width: 2.4; }
    [zoom>=16] { line-width: 2.8; }
  }
}


/**/