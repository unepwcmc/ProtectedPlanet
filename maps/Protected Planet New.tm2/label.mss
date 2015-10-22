// LABEL.MSS CONTENTS:
// 1__ Ocean & Marine Labels
// 2__ Place Names
//     2_1__ Countries
//     2_2__ States
//     2_3__ Cities
//     2_4__ Towns
//     2_5__ Villages
//     2_6__ Suburbs
//     2_7__ Neighbourhoods & Hamlets
// 4__ Water Labels
// 5__ Road Labels

// Font sets are defined in vars.mss

// =====================================================================
// 1__ OCEAN & MARINE LABELS
// =====================================================================

#marine_label["mapnik::geometry_type"=1],
#marine_label["mapnik::geometry_type"=2] {
  text-name: @name;
  text-face-name: @sans_lt_italic;
  text-fill: lighten(@water,20);

  // UN naming corrections
  [name_en="East Sea — Sea of Japan"] {text-name: "'日本海'";}

  ["mapnik::geometry_type"=1] {
    text-placement: point;
    text-wrap-width: 50;
    text-wrap-before: true;
  }
  ["mapnik::geometry_type"=2] {
    text-placement: line;
    text-avoid-edges: true;
  }
  [labelrank = 1] {
    [zoom = 3] {
      text-size: 20;
      text-character-spacing: 8;
      text-line-spacing: 16;
    }
    [zoom = 4] {
      text-size: 25;
      text-character-spacing: 16;
      text-line-spacing: 24;
    }
    [zoom = 5] {
      text-size: 30;
      text-character-spacing: 20;
      text-line-spacing: 32;
    }
  }
  [labelrank = 2] {
    [zoom = 3] {
      text-size: 13;
      text-character-spacing: 1;
      text-line-spacing: 6;
    }
    [zoom = 4] {
      text-size: 14;
      text-character-spacing: 2;
      text-line-spacing: 8;
    }
    [zoom = 5] {
      text-size: 20;
      text-character-spacing: 4;
      text-line-spacing: 8;
    }
    [zoom = 6] {
      text-size: 24;
      text-character-spacing: 5;
      text-line-spacing: 10;
    }
  }
  [labelrank = 3] {
    [zoom = 3] {
      text-size: 12;
      text-character-spacing: 2;
      text-line-spacing: 3;
    }
    [zoom = 4] {
      text-size: 13;
      text-character-spacing: 3;
      text-line-spacing: 8;
    }
    [zoom = 5] {
      text-size: 15;
      text-character-spacing: 4;
      text-line-spacing: 8;
    }
    [zoom = 6] {
      text-size: 18;
      text-character-spacing: 5;
      text-line-spacing: 10;
    }
  }
  [labelrank = 4][zoom = 4],
  [labelrank = 5][zoom = 5],
  [labelrank = 6][zoom = 6] {
    text-size: 12;
    text-character-spacing: 2;
    text-line-spacing: 6;
  }
  [labelrank = 4][zoom = 5],
  [labelrank = 5][zoom = 6],
  [labelrank = 6][zoom = 7] {
    text-size: 14;
    text-character-spacing: 3;
    text-line-spacing: 8;
  }
  [labelrank = 4][zoom = 6],
  [labelrank = 5][zoom = 7] {
    text-size: 16;
    text-character-spacing: 4;
    text-line-spacing: 1;
  }
}




// =====================================================================
// 2__ PLACE NAMES
// =====================================================================

// 2_1__ Countries _____________________________________________________

#country_label_line {
  line-color: @admin_2;
  line-opacity: 0.3;
  line-width: 0.8;
  line-dasharray: 5,2;
}

#country_label[zoom<=10] {
  text-name: @name;
  
  // UN naming corrections
  [name_en="Bolivia"] {text-name: "'Bolivia (Plurinational state of)'";}
  [name_en="Venezuela"] {text-name: "'Venezuela (Bolivarian Republic of)'";}
  [name_en="Republic of Macedonia"] {text-name: "'The former Yugoslav Republic of Macedonia'";}
  [name_en="Taiwan"] {text-name: "'Taiwan Province of China'"}
  
  text-face-name: @sans_bold;
  text-placement: point;
  [zoom=2] { text-opacity: 0.75; }
  text-size: 10;
  text-fill: @country_text;
  text-halo-fill: @country_halo;
  text-halo-radius: 1;
  text-halo-rasterizer: fast;
  text-wrap-width: 30;
  text-line-spacing: -2;
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
  text-fill: @state_text;
  text-halo-fill: @country_halo;
  text-halo-radius: 1.5;
  text-halo-rasterizer: fast;
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
    text-halo-radius: 2;
    text-size: 16;
    text-character-spacing: 2;
    [area>50000] { text-size: 18; text-character-spacing: 2; }
    text-wrap-width: 100;
  }
}

// 2_3__ Cities ________________________________________________________

// City labels with dots for low zoom levels.
// The separate attachment keeps the size of the XML down.
#place_label::citydots[zoom>=4][zoom<=7][localrank<=2] {
  // explicitly defining all the `ldir` values wer'e going
  // to use shaves a bit off the final project.xml size
  [ldir='N'],[ldir='S'],[ldir='E'],[ldir='W'],
  [ldir='NE'],[ldir='SE'],[ldir='SW'],[ldir='NW'] {
    shield-file: url("img/icon/dot-small.png");
    shield-unlock-image: true;
    shield-name: @name;
    shield-face-name: @sans;
    shield-placement: point;
    shield-fill: @city_text;
    shield-halo-fill: #fff;
    shield-halo-radius: 1.5;
    shield-opacity:0.5;
    shield-min-distance: 3;
    shield-wrap-width: 40;
    shield-line-spacing: -4;
    shield-size: 12;
    [zoom>=5] {
      [scalerank>=0][scalerank<=2] { shield-size: 13; }
      [scalerank>=3][scalerank<=5] { shield-size: 12; }
    }
    [zoom>=6] {
      [scalerank>=0][scalerank<=2] { shield-size: 14; }
      [scalerank>=3][scalerank<=5] { shield-size: 12; }
    }
    [zoom=7] {
      [scalerank>=0][scalerank<=2] { shield-size: 15; }
      [scalerank>=3][scalerank<=5] { shield-size: 13; }
      [scalerank>=6] { shield-size: 12; }
    }
    [ldir='E'] { shield-text-dx: 5; }
    [ldir='W'] { shield-text-dx: -5; }
    [ldir='N'] { shield-text-dy: -5; }
    [ldir='S'] { shield-text-dy: 8; }
    [ldir='NE'] { shield-text-dx: 4; shield-text-dy: -3; }
    [ldir='SE'] { shield-text-dx: 4; shield-text-dy: 5; }
    [ldir='SW'] { shield-text-dx: -4; shield-text-dy: 5; }
    [ldir='NW'] { shield-text-dx: -4; shield-text-dy: -3; }
  }
}

// For medium to high zoom levels we do away with the dot
// and center place labels on their point location.
#place_label[type='city'][zoom>=8][zoom<=15][localrank<=2] {
  text-name: @name;
  text-face-name: @sans;
  text-placement: point;
  text-fill: @city_text;
  text-halo-fill: #fff;
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
    text-fill: lighten(@city_text,10);
    text-size: 19;
    text-wrap-width: 300;
    [scalerank>=0][scalerank<=1] { text-size: 20; }
    [scalerank>=2][scalerank<=3] { text-size: 20; }
    [scalerank>=4][scalerank<=5] { text-size: 19; }
    [scalerank>=6] { text-size: 18; }
  }
  [zoom=15] {
    text-fill: lighten(@city_text,10);
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
  text-fill: @town_text;
  text-halo-fill: @town_halo;
  text-halo-radius: 1.5;
  text-halo-rasterizer: fast;
  text-wrap-width: 75;
  text-wrap-before: true;
  text-line-spacing: -4;
  text-size: 11;
  [zoom>=8] { text-size: 12; }
  [zoom>=10] { text-size: 13; text-halo-radius: 2; }
  [zoom>=11] { text-size: 14; }
  [zoom>=12] { text-size: 15; text-wrap-width: 80; }
  [zoom>=13] { text-size: 16; text-wrap-width: 120; }
  [zoom>=14] { text-size: 18; text-wrap-width: 160; }
  [zoom>=15] { text-size: 20; text-wrap-width: 200; }
  [zoom>=16] { text-size: 22; text-wrap-width: 240; }
}

// 2_5 Villages ______________________________________________________

#place_label[type='village'][zoom>=10][zoom<=14][localrank<=2],
#place_label[type='village'][zoom>=15][zoom<=17] {
  text-name: @name;
  text-face-name: @sans;
  text-placement: point;
  text-fill: @town_text;
  text-size: 11;
  text-halo-fill: @town_halo;
  text-halo-radius: 1.5;
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

#place_label[type='suburb'][zoom>=12][zoom<=14][localrank<=1],
#place_label[type='suburb'][zoom>=15][zoom<=18] {
  text-name: @name;
  text-face-name: @sans_lt;
  text-placement: point;
  text-fill: @other_text;
  text-size: 11;
  text-halo-fill: @other_halo;
  text-halo-radius: 1.5;
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

#place_label[zoom>=13][zoom<=14][localrank<=1],
#place_label[zoom>=15][zoom<=18] {
  [type='hamlet'],
  [type='neighbourhood'] {
    text-name: @name;
    text-face-name: @sans_lt;
    text-placement: point;
    text-fill: @other_text;
    text-size: 11;
    text-halo-fill: @other_halo;
    text-halo-radius: 1.5;
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

#water_label {
  [zoom<=15][area>200000],
  [zoom=16][area>50000],
  [zoom=17][area>10000],
  [zoom>=18][area>0]{
    text-name: @name;
    text-halo-radius: 1.5;
    text-halo-rasterizer: fast;
    text-size: 11;
    text-wrap-width: 50;
    text-wrap-before: true;
    text-halo-fill: #fff;
    text-line-spacing: -2;
    text-face-name: @sans_italic;
    text-fill: @water * 0.75;
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
    text-halo-radius: 2;
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

#waterway_label[class='river'][zoom>=13],
#waterway_label[class='canal'][zoom>=15],
#waterway_label[class='stream'][zoom>=17],
#waterway_label[class='stream_intermittent'][zoom>=17] {
  text-avoid-edges: true;
  text-name: @name;
  text-face-name: @sans_italic;
  text-fill: @water * 0.75;
  text-halo-fill: fadeout(#fff,80%);
  text-halo-radius: 1.5;
  text-halo-rasterizer: fast;
  text-placement: line;
  text-size: 10;
  text-character-spacing: 1;
  [class='river'][zoom=14],
  [class='canal'][zoom=16],
  [class='stream'][zoom>=18],
  [class='stream_intermittent'][zoom>=18] {
    text-size: 10;
  }
  [class='river'][zoom=15],
  [class='canal'][zoom>=17] {
    text-size: 11;
  }
  [class='river'][zoom>=16],
  [class='canal'][zoom>=18] {
    text-size: 14;
    text-spacing: 300;
  }
}


// =====================================================================
// 5__ ROAD LABELS
// =====================================================================

// highway shield
#road_label[class='motorway'][reflen>0][reflen<=6],
#road_label[class='main'][reflen>0][reflen<=6] {
  shield-name: "[ref]";
  shield-size: 9;
  shield-file: url('img/shield/generic-sm-[reflen].png');
  shield-face-name: @sans_bold;
  shield-fill: #999B9A;
  shield-spacing: 200;
  shield-avoid-edges: true;
  // Workaround for Mapnik bug where shields are placed slightly over the
  // edge even when avoid-edges is true:
  shield-min-padding: 5;
  shield-min-distance: 40;
  [zoom>=12] { shield-min-distance: 50; }
  [zoom>=14] {
    shield-spacing: 400;
    shield-min-distance: 80;
    shield-size: 11;
    shield-file: url('img/shield/generic-md-[reflen].png');
  }
}

// regular labels
#road_label['mapnik::geometry_type'=2] {
  // Longer roads get a label earlier as they are likely to be more
  // important. This especially helps label density in rural/remote areas.
  // This z14 filter is *not* redundant to logic in SQL queries. Because z14
  // includes all data for z14+ via overzooming, the streets included in a
  // z14 vector tile include more features than ideal for optimal performance.
  [class='motorway'][zoom>=12],
  [class='main'][zoom>=12],
  [class='street'][zoom<=14][len>2500],
  [class='street'][zoom>=15],
  [class='street_limited'] {
    text-avoid-edges: true;
    text-transform: uppercase;
    text-name: @name;
    text-character-spacing: 0.25;
    text-placement: line;
    text-face-name: @sans;
    text-fill: #999B9A;
    text-size: 8;
    text-halo-fill: @road_halo;
    text-halo-radius: 1.5;
    text-halo-rasterizer: fast;
    text-min-distance: 200; // only for labels w/ the same name
    [zoom>=14] { text-size: 9; }
    [zoom>=16] { text-size: 11; }
    [zoom>=18] { text-size: 12; }
    [class='motorway'],
    [class='main'] {
      [zoom>=14] { text-size: 10; }
      [zoom>=16] { text-size: 11; text-face-name: @sans_bold; }
      [zoom>=17] { text-size: 12; }
      [zoom>=18] { text-size: 14; }
    }
  }
}

// less prominent labels for all other types, by length
#road_label['mapnik::geometry_type'=2]
[class!='motorway']
[class!='main']
[class!='street']
[class!='street_limited'] {
  [len>10000][zoom>=12],
  [len>5000][zoom>=13],
  [len>2500][zoom>=14],
  [len>1200][zoom>=15],
  [len>0][zoom>=16] {
    text-avoid-edges: true;
    text-name: @name;
    text-character-spacing: 0.25;
    text-placement: line;
    text-face-name: @sans;
    text-fill: #999B9A;
    text-size: 9;
    text-halo-fill: @road_halo;
    text-halo-radius: 1.5;
    text-halo-rasterizer: fast;
    text-min-distance: 200; // only for labels w/ the same name
    [zoom>=17] { text-size: 10; }
    [zoom>=18] { text-size: 11; }
  }
}

// =====================================================================
// ADDRESS LABELS
// =====================================================================

#housenum_label[zoom>=18] {
  text-name:'[house_num]';
  text-face-name: @sans_lt_italic;
  text-fill: darken(@building, 20%);
  text-wrap-width: 50;
  text-wrap-before: true;
  text-placement:point;
  text-size: 9;
  [zoom>=19] {
    text-size: 11;
    text-character-spacing: -0.5;
  }
}


/**/
