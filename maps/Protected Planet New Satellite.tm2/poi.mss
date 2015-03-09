// =====================================================================
// POI LABELS
// =====================================================================

#poi_label[maki=''] { opacity:1; } // hack for mapnik#1952

#poi_label[type!='Aerodrome'][type!='Rail Station'][scalerank<4] {
  [zoom<13],
  [zoom>=13][scalerank=1][localrank<=1],
  [zoom>=14][scalerank<=1][localrank<=2],
  [zoom>=15][scalerank<=2][localrank<=2],
  [zoom>=16][localrank<=3],
  [zoom>=17][localrank<=16],
  [zoom>=18] {
    text-name: @name;
    text-face-name: @sans;
    text-fill: @place_text;
    text-halo-fill: fadeout(@place_halo,82);
    text-halo-radius: 1.5;
    text-halo-rasterizer: fast;
    text-line-spacing: -4;
    text-wrap-width: 80;
    text-wrap-before: true;
    [scalerank=1] {
      [zoom>=15] { text-size: 11; text-wrap-width: 100; }
      [zoom>=16] { text-size: 12; text-wrap-width: 120; }
      [zoom>=17] { text-size: 14; text-wrap-width: 130; }
    }
    [scalerank=2] {
      [zoom>=16] { text-size: 11; text-wrap-width: 100; }
      [zoom>=17] { text-size: 12; text-wrap-width: 120; }
    }
    [scalerank>=3] {
      [zoom>=17] { text-size: 11; text-wrap-width: 100; }
      [zoom>=19] { text-size: 12; text-wrap-width: 120; }
    }
  }
}


// =====================================================================
// 6__ TRANSPORTATION ICONS + LABELS
// =====================================================================

// 6_1__ Rail Stations _________________________________________________

#poi_label[type='Rail Station'][network=''] { opacity:1; } // hack for mapnik#1952

// Note: != null condition is a workaround for mapnik#1952.
#poi_label[type='Rail Station'][network!=null][scalerank=1][zoom>=14],
#poi_label[type='Rail Station'][network!=null][scalerank=2][zoom>=15],
#poi_label[type='Rail Station'][network!=null][scalerank=3][zoom>=16] {
  marker-file: url("img/rail/[network]-12.svg");
  marker-height: 12;
  marker-allow-overlap: false;
  [zoom=16] {
    marker-file: url("img/rail/[network]-18.svg");
    marker-height: 18;
  }
  [zoom>16] {
    marker-file: url("img/rail/[network]-12.svg");
    marker-height:24;
  }
  [zoom>15] {
    text-name: @name;
    text-face-name: @sans;
    text-fill: @place_text;
    text-halo-fill: fadeout(@place_halo,90);
    text-halo-radius: 2;
    text-halo-rasterizer: fast;
    text-size: 11;
    text-wrap-width: 80;
    text-placement-type: simple;
    text-dx: 11; text-dy: 11;
    text-placements: "S,N,E,W";
    [zoom>=17] {
      text-size: 12;
      text-dx: 15; text-dy: 15;
    }
  }
}

// 6_2__ Airports ______________________________________________________

#poi_label[type='Aerodrome'][zoom>=10] {
  marker-file: url("img/maki-classic/[maki]-12.svg");
  text-name: "''";
  text-size: 10;
  text-fill: @place_text;
  text-halo-fill: fadeout(@place_halo,90);
  text-halo-radius: 2;
  text-halo-rasterizer: fast;
  text-face-name: @sans;
  text-placement-type: simple;
  text-placements: "S,N,E,W";
  text-dx: 8; text-dy: 8;
  [zoom>=11][zoom<=13][scalerank=1],
  [zoom>=12][zoom<=13][scalerank=2] {
    text-name: [ref];
  }
  [zoom>=14] {
    text-name: @name;
    text-wrap-before: true;
  }
  [zoom>=11][scalerank=1],
  [zoom>=12][scalerank=2],
  [zoom>=14] {
    marker-file: url("img/maki-classic/[maki]-18.svg");
    text-size: 10;
    text-dx: 12; text-dy: 12;
    text-wrap-width: 80;
  }
  [zoom>=13][scalerank=1],
  [zoom>=14][scalerank=2],
  [zoom>=15] {
    marker-file: url("img/maki-classic/[maki]-24.svg");
    text-size: 12;
    text-dx: 15; text-dy: 15;
    text-wrap-width: 100;
  }
  [zoom>=14][scalerank=1],
  [zoom>=15][scalerank=2],
  [zoom>=16] {
    marker-file: url("img/maki-classic/[maki]-24.svg");
    text-size: 14;
    text-dx: 19; text-dy: 19;
    text-wrap-width: 120;
  }
}