// =====================================================================
// 2__ PLACE NAMES
// =====================================================================

// 2_1__ Countries _____________________________________________________

#country_label_line {
  line-color: @admin_2;
  line-opacity: 0.8;
  line-width: 0.8;
  line-dasharray: 5,2;
}

// these styles assume usage of custom admin_label tables.
#country_label[zoom<=10] {
  text-name: @name;
  text-face-name: @sans_bold;
  text-placement: point;
  [zoom=2] { text-opacity:.75; }
  text-size: 10;
  text-fill: @place_text;
  text-halo-fill: fadeout(@place_halo,95);
  text-halo-radius: 2;
  text-halo-rasterizer: fast;
  text-wrap-width: 30;
  text-min-distance: 2;
  text-line-spacing: -4;
  [scalerank=1] {
    [zoom=2]  { text-size: 12; text-wrap-width: 60; }
    [zoom=3]  { text-size: 13; text-wrap-width: 60; }
    [zoom=4]  { text-size: 14; text-wrap-width: 90; }
    [zoom=5]  { text-size: 20; text-wrap-width: 120; }
    [zoom>=6] { text-size: 20; text-wrap-width: 120; }
  }
  [scalerank=2] {
    [zoom=3]  { text-size: 12; }
    [zoom=4]  { text-size: 13; }
    [zoom=5]  { text-size: 17; }
    [zoom>=6] { text-size: 20; }
  }
  [scalerank=3] {
    [zoom=4]  { text-size: 11; }
    [zoom=5]  { text-size: 15; }
    [zoom=6]  { text-size: 17; }
    [zoom=7]  { text-size: 18; text-wrap-width: 60; }
    [zoom>=8] { text-size: 20; text-wrap-width: 120; }
  }
  [scalerank=4] {
    [zoom=5] { text-size: 13; }
    [zoom=6] { text-size: 15; text-wrap-width: 60  }
    [zoom=7] { text-size: 16; text-wrap-width: 90; }
    [zoom=8] { text-size: 18; text-wrap-width: 120; }
    [zoom>=9] { text-size: 20; text-wrap-width: 120; }
  }
  [scalerank=5] {
    [zoom=5] { text-size: 12; }
    [zoom=6] { text-size: 13; }
    [zoom=7] { text-size: 14; text-wrap-width: 60; }
    [zoom=8] { text-size: 16; text-wrap-width: 90; }
    [zoom>=9] { text-size: 18; text-wrap-width: 120; }
  }
  [scalerank>=6] {
    [zoom=6] { text-size: 11; }
    [zoom=7] { text-size: 12; }
    [zoom=8] { text-size: 14; }
    [zoom>=9] { text-size: 16; }
  }
}


// 2_2__ States ________________________________________________________

#state_label[zoom>=4][zoom<=10] {
  text-name: @name;
  text-face-name: @sans_lt;
  text-placement: point;
  text-fill: @place_text;
  text-halo-fill: fadeout(@place_halo,97);
  text-halo-radius: 2;
  text-halo-rasterizer: fast;
  text-min-distance: 1;
  text-size: 10;
  [zoom>=5][zoom<=6] {
    [area>10000] { text-size: 12; }
    [area>50000] { text-size: 14; }
    text-wrap-width: 40;
  }
  [zoom>=7][zoom<=8] {
    text-size: 14;
    [area>50000] { text-size: 16; text-character-spacing: 1; }
    [area>100000] { text-size: 18; text-character-spacing: 3; }
    text-wrap-width: 60;
  }
  [zoom>=9][zoom<=10] {
    text-size: 16;
    text-character-spacing: 2;
    [area>50000] { text-size: 18; text-character-spacing: 2; }
    text-wrap-width: 100;
  }
}

// 2_3__ Cities ________________________________________________________

// City labels with dots for low zoom levels.
// The separate attachment keeps the size of the XML down.
#place_label::citydots[type='city'][zoom>=4][zoom<=7][localrank<=2] {
  // explicitly defining all the `ldir` values wer'e going
  // to use shaves a bit off the final project.xml size
  [ldir='N'],[ldir='S'],[ldir='E'],[ldir='W'],
  [ldir='NE'],[ldir='SE'],[ldir='SW'],[ldir='NW'] {
    text-name: @name;
    text-size: 11;
    [scalerank>=0][scalerank<=1] {
      [zoom=4] { text-face-name: @sans_bold; }
      [zoom=5] { text-size: 13; marker-width: 5; }
      [zoom>=6] { text-size: 14; marker-width: 6; }
    }
    [scalerank>=2][scalerank<=3] {
      [zoom=5] { text-size: 11; }
      [zoom=6] { text-size: 12; marker-width: 5; }
      [zoom=7] { text-size: 13; marker-width: 6; }
    }
    [scalerank>=4][scalerank<=5] {
      [zoom=6] { text-size: 11; }
      [zoom=7] { text-size: 12; marker-width: 5; }
    }
    text-face-name: @sans;
    text-placement: point;
    text-fill: @place_text;
    text-halo-fill: fadeout(@place_halo,90);
    text-halo-radius: 1.75;
    text-halo-rasterizer: fast;
    [ldir='E'] { text-dx: 4; }
    [ldir='W'] { text-dx: -4; }
    [ldir='N'] { text-dy: -4; }
    [ldir='S'] { text-dy: 4; }
    [ldir='NE'] { text-dx: 3; text-dy: -3; }
    [ldir='SE'] { text-dx: 3; text-dy: 3; }
    [ldir='SW'] { text-dx: -3; text-dy: 3; }
    [ldir='NW'] { text-dx: -3; text-dy: -3; }
    marker-width: 4;
    marker-fill: @place_text;
    marker-line-width: 1;
    marker-line-color: @place_halo;
  }
}

// For medium to high zoom levels we do away with the dot
// and center place labels on their point location.
#place_label[type='city'][zoom>=8][zoom<=15][localrank<=2] {
  text-name: @name;
  text-face-name: @sans;
  text-placement: point;
  text-fill: @place_text;
  text-halo-fill: fadeout(@place_halo,97);
  text-halo-radius: 2;
  text-halo-rasterizer: fast;
  text-wrap-width: 40;
  text-line-spacing: -4;
  // We keep the scalerank filters the same for each zoom level.
  // This is slightly inefficient-looking CartoCSS, but it saves
  // some space in the project.xml
  [zoom=8] {
    text-size: 13;
    text-wrap-width: 60;
    [scalerank>=0][scalerank<=1] { text-size: 18; }
    [scalerank>=2][scalerank<=3] { text-size: 16; }
    [scalerank>=4][scalerank<=5] { text-size: 15; }
    [scalerank>=6] { text-size: 13; }
  }
  [zoom=9] {
    text-size: 14;
    text-wrap-width: 60;
    [scalerank>=0][scalerank<=1] { text-size: 19; }
    [scalerank>=2][scalerank<=3] { text-size: 17; }
    [scalerank>=4][scalerank<=5] { text-size: 16; }
    [scalerank>=6] { text-size: 14; }
  }
  [zoom=10] {
    text-size: 15;
    text-wrap-width: 70;
    [scalerank>=0][scalerank<=1] { text-size: 20; }
    [scalerank>=2][scalerank<=3] { text-size: 19; }
    [scalerank>=4][scalerank<=5] { text-size: 17; }
    [scalerank>=6] { text-size: 15; }
  }
  [zoom=11] {
    text-size: 16;
    text-wrap-width: 80;
    [scalerank>=0][scalerank<=1] { text-size: 20; }
    [scalerank>=2][scalerank<=3] { text-size: 19; }
    [scalerank>=4][scalerank<=5] { text-size: 17; }
    [scalerank>=6] { text-size: 16; }
  }
  [zoom=12] {
    text-size: 17;
    text-wrap-width: 100;
    [scalerank>=0][scalerank<=1] { text-size: 20; }
    [scalerank>=2][scalerank<=3] { text-size: 19; }
    [scalerank>=4][scalerank<=5] { text-size: 18; }
    [scalerank>=6] { text-size: 17; }
  }
  [zoom=13] {
    text-size: 18;
    text-wrap-width: 200;
    [scalerank>=0][scalerank<=1] { text-size: 20; }
    [scalerank>=2][scalerank<=3] { text-size: 19; }
    [scalerank>=4][scalerank<=5] { text-size: 19; }
    [scalerank>=6] { text-size: 17; }
  }
  [zoom=14] {
    text-fill: @place_text;
    text-size: 19;
    text-wrap-width: 300;
    [scalerank>=0][scalerank<=1] { text-size: 20; }
    [scalerank>=2][scalerank<=3] { text-size: 20; }
    [scalerank>=4][scalerank<=5] { text-size: 19; }
    [scalerank>=6] { text-size: 18; }
  }
  [zoom=15] {
    text-fill: @place_text;
    text-size: 20;
    text-wrap-width: 400;
    [scalerank>=0][scalerank<=1] { text-size: 20; }
    [scalerank>=2][scalerank<=3] { text-size: 20; }
    [scalerank>=4][scalerank<=5] { text-size: 20; }
    [scalerank>=6] { text-size: 19; }
  }
}

// 2_4__ Towns _________________________________________________________

#place_label[type='town'][zoom>=8][zoom<=17][localrank<=2] {
  text-name: @name;
  text-face-name: @sans;
  text-placement: point;
  text-fill: @place_text;
  text-halo-fill: fadeout(@place_halo,95);
  text-halo-radius: 2;
  text-halo-rasterizer: fast;
  text-wrap-width: 60;
  text-wrap-before: true;
  text-line-spacing: -4;
  [zoom>=13] { text-min-distance: 4; }
  text-size: 12;
  [zoom>=11] { text-size: 14; text-min-distance: 18; }
  [zoom>=12] { text-size: 15; text-wrap-width: 80; }
  [zoom>=13] { text-size: 16; text-wrap-width: 120; }
  [zoom>=14] { text-size: 18; text-wrap-width: 160; }
  [zoom>=15] { text-size: 20; text-wrap-width: 200; }
  [zoom>=16] { text-size: 22; text-wrap-width: 240; }
}

// 2_5 Villages ______________________________________________________

#place_label[type='village'][zoom>=10][zoom<=17][localrank<=2] {
  text-name: @name;
  text-face-name: @sans;
  text-placement: point;
  text-fill: @place_text;
  text-size: 11;
  text-halo-fill: fadeout(@place_halo,95);
  text-halo-radius: 2;
  text-halo-rasterizer: fast;
  text-wrap-width: 60;
  text-wrap-before: true;
  text-line-spacing: -4;
  [zoom>=12] { text-size: 12; }
  [zoom>=13] { text-wrap-width: 80; }
  [zoom>=14] { text-size: 14; text-wrap-width: 100; }
  [zoom>=15] { text-size: 16; text-wrap-width: 120; }
  [zoom>=16] { text-size: 18; text-wrap-width: 160; }
  [zoom=17] { text-size: 20; text-wrap-width: 200; }
}

// 2_6__ Suburbs _______________________________________________________

#place_label[type='suburb'][zoom>=12][zoom<=17][localrank<=2] {
  text-name: @name;
  text-face-name: @sans;
  text-placement: point;
  text-fill: @place_text;
  text-size: 11;
  text-halo-fill: fadeout(@place_halo,95);
  text-halo-radius: 2;
  text-halo-rasterizer: fast;
  text-wrap-width: 60;
  text-wrap-before: true;
  text-line-spacing: -2;
  [zoom>=13] { text-size: 12; text-min-distance: 20; }
  [zoom>=14] { text-size: 13; text-wrap-width: 80; }
  [zoom>=15] { text-size: 14; text-wrap-width: 120; }
  [zoom>=16] { text-size: 16; text-wrap-width: 160; }
  [zoom>=17] { text-size: 20; text-wrap-width: 200; }
}

// 2_7__ Neighbourhoods & Hamlets ______________________________________

#place_label[zoom>=13][zoom<=18][localrank<=2] {
  [type='hamlet'],
  [type='neighbourhood'] {
    text-name: @name;
    text-face-name: @sans;
    text-placement: point;
    text-fill: @place_text;
    text-size: 11;
    text-halo-fill: fadeout(@place_halo,95);
    text-halo-radius: 2;
    text-halo-rasterizer: fast;
    text-wrap-width: 60;
    text-wrap-before: true;
    text-line-spacing: -2;
    [zoom>=14] { text-size: 12; text-wrap-width: 80; }
    [zoom>=16] { text-size: 14; text-wrap-width: 100; }
    [zoom>=17] { text-size: 16; text-wrap-width: 130; }
    [zoom>=18] { text-size: 18; text-wrap-width: 160; }
  }
}


// =====================================================================
// 4__ WATER LABELS
// =====================================================================

#marine_label {
  [name_en=~".*Sea.*Japan"] {text-name: "'日本海'";}  
}

#water_label {
  [zoom<=15][area>200000],
  [zoom=16][area>50000],
  [zoom=17][area>10000],
  [zoom>=18][area>0]{
    text-name: @name;
    text-halo-fill: fadeout(@place_halo,90);
    text-halo-radius: 1.5;
    text-halo-rasterizer: fast;
    text-size: 11;
    text-wrap-width: 50;
    text-wrap-before: true;
    text-line-spacing: -2;
    text-face-name: @sans_italic;
    text-fill: @place_text;
  }
  [zoom>=14][area>3200000],
  [zoom>=15][area>800000],
  [zoom>=16][area>200000],
  [zoom>=17][area>50000],
  [zoom>=18][area>10000] {
    text-size: 12;
    text-wrap-width: 75;
  }
  [zoom>=15][area>3200000],
  [zoom>=16][area>800000],
  [zoom>=17][area>200000],
  [zoom>=18][area>50000] {
    text-size: 14;
    text-wrap-width: 100;
  }
  [zoom>=16][area>3200000],
  [zoom>=17][area>800000],
  [zoom>=18][area>200000] {
    text-size: 16;
    text-wrap-width: 125;
  }
  [zoom>=17][area>3200000],
  [zoom>=18][area>800000] {
    text-size: 18;
    text-wrap-width: 150;
  }
}

#waterway_label[type='river'][zoom>=13],
#waterway_label[type='canal'][zoom>=15],
#waterway_label[type='stream'][zoom>=17] {
  text-avoid-edges: true;
  text-name: @name;
  text-face-name: @sans_italic;
  text-halo-fill: fadeout(@place_halo,90);
  text-fill: @place_text;
  text-halo-radius: 1.5;
  text-halo-rasterizer: fast;
  text-placement: line;
  text-min-distance: 400;
  text-size: 10;
  text-character-spacing: 1;
  [type='river'][zoom=14],
  [type='canal'][zoom=16],
  [type='stream'][zoom>=18] {
    text-size: 10;
  }
  [type='river'][zoom=15],
  [type='canal'][zoom>=17] {
    text-size: 11;
  }
  [type='river'][zoom>=16],
  [type='canal'][zoom>=18] {
    text-size: 14;
    text-spacing: 300;
  }
}

/**/