// ==================================================================
// ROAD & RAIL LINES
// ==================================================================

// At Z12 and above there are 3 basic levels of road styles:
// - ::line, for single line (caseless) rendering
// - ::case, the casing part of an outlined road
// - ::fill, the fill part of an outlined road

// Road width variables that are used in road & bridge styles
@rdz08_maj: 1.2;
@rdz09_maj: 1.4; @rdz09_med: 0.6; @rdz09_min: 0;
@rdz10_maj: 1.8; @rdz10_med: 0.8; @rdz10_min: 0;
@rdz11_maj: 2;   @rdz11_med: 1.2; @rdz11_min: 0;
@rdz12_maj: 2.5; @rdz12_med: 1.4; @rdz12_min: 0.5;
@rdz13_maj: 3;   @rdz13_med: 2.0; @rdz13_min: 1;
@rdz14_maj: 4;   @rdz14_med: 3;   @rdz14_min: 1.6;
@rdz15_maj: 5;   @rdz15_med: 4;   @rdz15_min: 2;
@rdz16_maj: 9;   @rdz16_med: 7;   @rdz16_min: 3;
@rdz17_maj: 14;  @rdz17_med: 12;  @rdz17_min: 6;
@rdz18_maj: 20;  @rdz18_med: 16;  @rdz18_min: 10;

// Attachment ordering + any style-level rules

#tunnel {
  // tunnel is drawn in a single attachment to allow for
  // style-level opacity. Side effect is that casing overlaps
  // where tunnels merge.
  opacity: 0.15;
}

#road::line,
#bridge::line {
  opacity: 1;
}

#road::case { opacity: 0.12; }
#bridge::case { opacity: 0.2; }

#road::fill,
#bridge::fill {
  opacity: 1;
}

// ---- Line ----------------------------------------------------

// Puts caseless roads beneath casings to highlight major roads.
// Tunnels and bridges still include casing, tunnels require
// appropriate attachments too.

#road::line[class='motorway'][zoom>=5][zoom<=7] {
  ['mapnik::geometry_type'=2] {
    line-color: @motorway_line;
    line-width: 0.1;
    [zoom=7] { line-width: 1; }
  }
}

#road::line[class='main'][zoom>=5][zoom<=10] {
  ['mapnik::geometry_type'=2] {
    line-color: @main_line;
    line-width: 0.5;
    [zoom=7] { line-width: 0.6; }
    [zoom=8] { line-width: 0.7; }
    [zoom=9] { line-width: @rdz09_med; }
    [zoom=10] { line-width: @rdz10_med; }
  }
}

#road::line[class='street'][zoom>=12][zoom<=13] {
  ['mapnik::geometry_type'=2] {
    line-color: @road_line;
    [zoom=12] { line-width: @rdz12_min; }
    [zoom=13] { line-width: @rdz13_min; }
  }
  ['mapnik::geometry_type'=3] {
    polygon-fill: @road_line;
  }
}

#road::line[class='street_limited'][zoom>=14],
#tunnel[class='street_limited'][zoom>=14],
#bridge::fill[class='street_limited'][zoom>=14] {
  ['mapnik::geometry_type'=2] {
    line-color: @road_fill;
    line-join: round;
    line-dasharray: 6, 2;
    [zoom=15] { line-dasharray: 8, 2; }
    [zoom=16] { line-dasharray: 10, 2; }
    [zoom=17] { line-dasharray: 12, 3; }
    [zoom>17] { line-dasharray: 15, 3; }
    [zoom=14] { line-width: (@rdz14_min * 0.8); }
    [zoom=15] { line-width: (@rdz15_min * 0.8); }
    [zoom=16] { line-width: (@rdz16_min * 0.8); }
    [zoom=17] { line-width: (@rdz17_min * 0.8); }
    [zoom>17] { line-width: (@rdz18_min * 0.8); }
  }
  ['mapnik::geometry_type'=3] {
    polygon-fill: @road_fill;
    polygon-opacity: 0.5;
  }
}
#road::line[class='street_limited'][zoom>=14] {
  ['mapnik::geometry_type'=1] {
    marker-allow-overlap: true;
    marker-ignore-placement: true;
    marker-fill: @road_fill;
    marker-line-opacity: 0;
    [zoom=14] { line-width: @rdz14_min * 1.7; }
    [zoom=15] { line-width: @rdz15_min * 1.7; }
    [zoom=16] { line-width: @rdz16_min * 1.7; }
    [zoom=17] { line-width: @rdz17_min * 1.7; }
    [zoom>17] { line-width: @rdz18_min * 1.7; }
  }
}

#road::line[class='major_rail'][zoom=12] {
  line-color: @rail_line;
  line-dasharray: 1, 2;
  [zoom=11] { line-width: 0.2; }
  [zoom=12] { line-width: 0.4; }
}

#road::line[class='service'][zoom>=13],
#tunnel[class='service'][zoom>=13],
#bridge::fill[class='service'][zoom>=13] {
  ['mapnik::geometry_type'=2] {
    line-color: @road_line;
    [zoom=13] { line-width: @rdz13_min / 3; }
    [zoom=14] { line-width: @rdz14_min / 3; }
    [zoom=15] { line-width: @rdz15_min / 3; }
    [zoom=16] { line-width: @rdz16_min / 3; }
    [zoom=17] { line-width: @rdz17_min / 3; }
    [zoom>17] { line-width: @rdz18_min / 3; }
  }
  ['mapnik::geometry_type'=3] {
    polygon-fill: @road_line;
  }
}
#road::line[class='service'][zoom>=14] {
  ['mapnik::geometry_type'=1] {
    marker-allow-overlap: true;
    marker-ignore-placement: true;
    marker-fill: @road_line;
    marker-line-opacity: 0;
    [zoom=14] { marker-width: @rdz14_min / 3 * 1.8; }
    [zoom=15] { marker-width: @rdz15_min / 3 * 1.8; }
    [zoom=16] { marker-width: @rdz16_min / 3 * 1.8; }
    [zoom=17] { marker-width: @rdz17_min / 3 * 1.8; }
    [zoom>17] { marker-width: @rdz18_min / 3 * 1.8; }
  }
}

#road::line[class='driveway'][zoom>=15] {
  ['mapnik::geometry_type'=2] {
    line-opacity: 0.5;
    line-color: @road_line;
    [zoom=15] { line-width: @rdz15_min / 4; }
    [zoom=16] { line-width: @rdz16_min / 4; }
    [zoom=17] { line-width: @rdz17_min / 4; }
    [zoom>17] { line-width: @rdz18_min / 4; }
  }
  ['mapnik::geometry_type'=3] {
    polygon-fill: @road_line;
    polygon-opacity: 0.5;
  }
}

#bridge::fill['mapnik::geometry_type'=2],
#tunnel['mapnik::geometry_type'=2] {
  [class='path'][zoom>=14] {
    m/line-color: @land;
    m/line-width: 1 + 1;
    [zoom>=15] { m/line-width: 1.2 + 1; }
    [zoom>=16] { m/line-width: 1.4 + 1; }
    [zoom>=17] { m/line-width: 1.8 + 1; }
    [zoom>=18] { m/line-width: 2.6 + 1; }
  }
}
#road::line,
#tunnel,
#bridge::fill {
  [class='path'][zoom>=14] {
    ['mapnik::geometry_type'=2] {
      line-color: @path_line;
      line-opacity: 0.75;
      line-dasharray: 1 , 1;
      line-width: 1;
      [zoom>=15] { line-width: 1.2; line-dasharray: 1.2, 1.2; }
      [zoom>=16] { line-width: 1.4; line-dasharray: 1.4, 1.4; }
      [zoom>=17] { line-width: 1.8; line-dasharray: 1.8, 1.8; }
      [zoom>=18] { line-width: 2.6; line-dasharray: 2.6, 2.6; }
    }
  }
}

#bridge::fill[class='aerialway'][zoom>=13] {
  // aerialways are only in the bridge layer
  line-width:0.2;
  line-color:lighten(@road_case,50);
  line-opacity:0.85;
  [zoom=14] { line-width: @rdz14_min / 4; }
  [zoom=15] { line-width: @rdz15_min / 4; }
  [zoom=16] { line-width: @rdz16_min / 4; }
  [zoom=17] { line-width: @rdz17_min / 4; }
  [zoom>17] { line-width: @rdz18_min / 4; }
  // hatching
  b/line-width:5;
  b/line-color:lighten(@road_case,50);
  b/line-opacity:0.75;
  b/line-dasharray:0.2,18;
  b/line-clip:false;
  [zoom=14] {
    b/line-width: 6;
    b/line-dasharray: @rdz14_min / 4, 30;
  }
  [zoom=15] {
    b/line-width: 8;
    b/line-dasharray: @rdz15_min / 4, 40;
  }
  [zoom=16] {
    b/line-width: 11;
    b/line-dasharray: @rdz16_min / 4, 50;
  }
  [zoom=17] {
    b/line-width: 15;
    b/line-dasharray: @rdz17_min / 4, 60;
  }
  [zoom>17] {
    b/line-width: 20;
    b/line-dasharray: @rdz18_min / 4, 70;
  }
}


// ---- Casing --------------------------------------------------

#road::case[class='motorway'][zoom>=8],
#tunnel[class='motorway'][zoom>=10],
#bridge::case[class='motorway'][zoom>=10] {
  ['mapnik::geometry_type'=2] {
    line-color: @motorway_case;
    line-join: round;
    line-cap: round;
    [zoom=8]  { line-width: @rdz08_maj + 1.5; }
    [zoom=9]  { line-width: @rdz09_maj + 1.5; }
    [zoom=10] { line-width: @rdz10_maj + 1.5; }
    [zoom=11] { line-width: @rdz10_maj + 1.5; }
    [zoom=11] { line-width: @rdz11_maj + 1.5; }
    [zoom=12] { line-width: @rdz12_maj + 1.5; }
    [zoom=13] { line-width: @rdz13_maj + 2; }
    [zoom=14] { line-width: @rdz14_maj + 2.5; }
    [zoom=15] { line-width: @rdz15_maj + 3; }
    [zoom=16] { line-width: @rdz16_maj + 3; }
    [zoom=17] { line-width: @rdz17_maj + 3; }
    [zoom>17] { line-width: @rdz18_maj + 3; }
  }
}

#road::case[class='motorway_link'][zoom>=9],
#tunnel[class='motorway_link'][zoom>=9],
#bridge::case[class='motorway_link'][zoom>=9] {
  ['mapnik::geometry_type'=2] {
    line-color: @motorway_case;
    line-join: round;
    line-cap: round;
    [zoom=11] { line-width: @rdz11_maj / 2 + 2; }
    [zoom=12] { line-width: @rdz12_maj / 2 + 2; }
    [zoom=13] { line-width: @rdz13_maj / 2 + 2; }
    [zoom=14] { line-width: @rdz14_maj / 2 + 2; }
    [zoom=15] { line-width: @rdz15_maj / 2 + 2.5; }
    [zoom=16] { line-width: @rdz16_maj / 2 + 3; }
    [zoom=17] { line-width: @rdz17_maj / 2 + 4; }
    [zoom>17] { line-width: @rdz18_maj / 2 + 4; }
  }
}

#road::case[class='main'][zoom>=11],
#tunnel[class='main'][zoom>=11],
#bridge::case[class='main'][zoom>=11] {
  ['mapnik::geometry_type'=2] {
    line-color: @main_case;
    line-join: round;
    line-cap: round;
    [zoom=11] { line-width: @rdz11_med + 2; }
    [zoom=12] { line-width: @rdz12_med + 2; }
    [zoom=13] { line-width: @rdz13_med + 2; }
    [zoom=14] { line-width: @rdz14_med + 2; }
    [zoom=15] { line-width: @rdz15_med + 2.5; }
    [zoom=16] { line-width: @rdz16_med + 3; }
    [zoom=17] { line-width: @rdz17_med + 4; }
    [zoom>17] { line-width: @rdz18_med + 4; }
  }
  ['mapnik::geometry_type'=3] {
    line-color: @main_case;
    line-cap: round;
    line-join: round;
    line-width: 4;
  }
}
#road::case[class='main'][zoom>=11] {
  ['mapnik::geometry_type'=1] {
    marker-allow-overlap: true;
    marker-ignore-placement: true;
    [zoom=11] { marker-width: @rdz11_med * 1.8; }
    [zoom=12] { marker-width: @rdz12_med * 1.8; }
    [zoom=13] { marker-width: @rdz13_med * 1.8; }
    [zoom=14] { marker-width: @rdz14_med * 1.8; }
    [zoom=15] { marker-width: @rdz15_med * 1.8; }
    [zoom=16] { marker-width: @rdz16_med * 1.8; }
    [zoom=17] { marker-width: @rdz17_med * 1.8; }
    [zoom>17] { marker-width: @rdz18_med * 1.8; }
    marker-line-color: @main_case;
    [zoom=11] { marker-line-width: 2; }
    [zoom=12] { marker-line-width: 2; }
    [zoom=13] { marker-line-width: 2; }
    [zoom=14] { marker-line-width: 2; }
    [zoom=15] { marker-line-width: 2.5; }
    [zoom=16] { marker-line-width: 3; }
    [zoom=17] { marker-line-width: 4; }
    [zoom>17] { marker-line-width: 4; }
  }
}

// upper zoom limit is required for added specifity
#road::case[class='street'][zoom>=14],
#tunnel[class='street'][zoom>=14],
#bridge::case[class='street'][zoom>=14] {
  ['mapnik::geometry_type'=1] {
    marker-allow-overlap: true;
    marker-ignore-placement: true;
    [zoom=14] { marker-width: @rdz14_min * 1.8; }
    [zoom=15] { marker-width: @rdz15_min * 1.8; }
    [zoom=16] { marker-width: @rdz16_min * 1.8; }
    [zoom=17] { marker-width: @rdz17_min * 1.8; }
    [zoom>17] { marker-width: @rdz18_min * 1.8; }
    marker-line-color: @road_case;
    [zoom=14] { marker-line-width: 2; }
    [zoom=15] { marker-line-width: 2; }
    [zoom=16] { marker-line-width: 2.5; }
    [zoom=17] { marker-line-width: 3; }
    [zoom>17] { marker-line-width: 3; }
  }
  ['mapnik::geometry_type'=2] {
    line-color: @road_case;
    line-join: round;
    line-cap: round;
    [zoom=14] { line-width: @rdz14_min + 2; }
    [zoom=15] { line-width: @rdz15_min + 2; }
    [zoom=16] { line-width: @rdz16_min + 2.5; }
    [zoom=17] { line-width: @rdz17_min + 3; }
    [zoom>17] { line-width: @rdz18_min + 3; }
  }
  ['mapnik::geometry_type'=3] {
    line-color: @road_case;
    line-join: round;
    line-cap: round;
    line-width: 2;
    [zoom=16] { line-width: 2.5; }
    [zoom>=17] { line-width: 3; }
  }
}

#tunnel[class='service'][zoom>=16],
#bridge::case[class='service'][zoom>=16] {
  ['mapnik::geometry_type'=2] {
    line-color: @road_case;
    line-join: round;
    line-cap: butt;
    [zoom=16] { line-width: @rdz16_min / 3 + 2; }
    [zoom=17] { line-width: @rdz17_min / 3 + 2.5; }
    [zoom>17] { line-width: @rdz18_min / 3 + 3; }
  }
  ['mapnik::geometry_type'=3] {
    line-color: @road_case;
    line-join: round;
    line-cap: round;
    line-width: 2;
    [zoom=16] { line-width: 2.5; }
    [zoom>=17] { line-width: 3; }
  }
}

#tunnel[class='street_limited'][zoom>=14],
#bridge::case[class='street_limited'][zoom>=14] {
  ['mapnik::geometry_type'=2] {
    line-color: @road_case;
    line-join: round;
    line-cap: round;
    [zoom=14] { line-width: @rdz14_min * 0.75 + 1.8; line-opacity: 0.75; }
    [zoom=15] { line-width: @rdz15_min * 0.75 + 1.8; }
    [zoom=16] { line-width: @rdz16_min * 0.75 + 2; }
    [zoom=17] { line-width: @rdz17_min * 0.75 + 2; }
    [zoom>17] { line-width: @rdz18_min * 0.75 + 2; }
  }
  ['mapnik::geometry_type'=3] {
    line-color: @road_case;
    line-join: round;
    line-cap: round;
    line-width: 1.8;
    [zoom=16] { line-width: 2; }
    [zoom>=17] { line-width: 2; }
    polygon-fill: @land;
  }
}
#tunnel[class='street_limited'][zoom>=14]['mapnik::geometry_type'=2] {
  line-cap: butt;
  line-dasharray: 6 , 2;
}

#tunnel,
#bridge::case {
  [class='path'][zoom>=14] {
    line-join: round;
    line-color: @road_case;
    #tunnel { line-dasharray: 2, 2; }
    line-width: 1 + 2;
    [zoom=15] { line-width: 1.2 + 2; }
    [zoom=16] { line-width: 1.4 + 2.5; }
    [zoom=17] { line-width: 1.8 + 3; }
    [zoom>17] { line-width: 2.6 + 3; }
  }
}

#bridge::case[class='major_rail'][zoom>=13],
#bridge::case[class='minor_rail'][zoom>=15] {
  line-join: round;
  [zoom=14] { line-width: 1 + 2; }
  [zoom=15] { line-width: 1.5 + 3; }
  [zoom=16] { line-width: 2 + 4; }
  [zoom=17] { line-width: 3 + 5; }
  [zoom>17] { line-width: 3 + 6; }
}

#tunnel[class='major_rail'][zoom>=13],
#tunnel[class='minor_rail'][zoom>=15] {
  line-color: #000;
  line-opacity: 0.5;
  line-join: round;
  line-cap: butt;
  line-dasharray: 6 , 3;
  [zoom=14] { line-width: 1 + 2; }
  [zoom=15] { line-width: 1.5 + 3; }
  [zoom=16] { line-width: 2 + 4; }
  [zoom=17] { line-width: 3 + 5; }
  [zoom>17] { line-width: 3 + 6; }
}

#tunnel[zoom>=12]['mapnik::geometry_type'=2] {
  [class='motorway'],
  [class='motorway_link'],
  [class='main'],
  [class='street'],
  [class='street_limited'],
  [class='service'],
  [class='driveway'],
  [class='path'] {
    line-cap: butt;
    line-dasharray: 6 , 2;
  }
}

#bridge::case[zoom>=12]['mapnik::geometry_type'=2] {
  [class='motorway'],
  [class='motorway_link'],
  [class='main'],
  [class='street'],
  [class='street_limited'][zoom>=14],
  [class='service'][zoom>=14],
  [class='driveway'][zoom>=15],
  [class='path'][zoom>=16] {
    line-cap: butt;
  }
}

// solid background fill for dashed lines
#tunnel[zoom>=13] {
  ['mapnik::geometry_type'=2] {
    // colors & styles
    m/line-color: @land;
    m/line-join: round;
    // widths
    [zoom=13] {
      [class='main'] { m/line-width: @rdz13_med; }
      [class='street'] { m/line-width: @rdz13_min; }
      [class='major_rail'] { m/line-width: (0.8 + 1); }
    }
    [zoom=14] {
      [class='main'] { m/line-width: @rdz14_med; }
      [class='street'] { m/line-width: @rdz14_min; }
      [class='street_limited'] { m/line-width: @rdz14_min * 0.75; }
      [class='major_rail'] { m/line-width: (1 + 1); }
    }
    [zoom=15] {
      [class='main'] { m/line-width: @rdz15_med; }
      [class='street'] { m/line-width: @rdz15_min; }
      [class='street_limited'] { m/line-width: @rdz15_min * 0.75; }
      [class='service'] { m/line-width: @rdz15_min / 3; }
      [class='major_rail'] { m/line-width: (1.5 + 1); }
      [class='minor_rail'] { m/line-width: (1.5 + 1); }
    }
    [zoom=16] {
      [class='main'] { m/line-width: @rdz16_med; }
      [class='street'] { m/line-width: @rdz16_min; }
      [class='street_limited'] { m/line-width: @rdz16_min * 0.75; }
      [class='service'] { m/line-width: @rdz16_min / 3; }
      [class='path'] { m/line-width: (@rdz16_min / 4 + 1); }
      [class='major_rail'] { m/line-width: (2 + 1); }
      [class='minor_rail'] { m/line-width: (2 + 1); }
    }
    [zoom=17] {
      [class='main'] { m/line-width: @rdz17_med; }
      [class='street'] { m/line-width: @rdz17_min; }
      [class='street_limited'] { m/line-width: @rdz17_min * 0.75; }
      [class='service'] { m/line-width: @rdz17_min / 3; }
      [class='path'] { m/line-width: (@rdz17_min / 4 + 2); }
      [class='major_rail'] { m/line-width: (3 + 2); }
      [class='minor_rail'] { m/line-width: (3 + 2); }
    }
    [zoom>17] {
      [class='main'] { m/line-width: @rdz18_med; }
      [class='street'] { m/line-width: @rdz18_min; }
      [class='street_limited'] { m/line-width: @rdz18_min * 0.75; }
      [class='service'] { m/line-width: @rdz18_min / 3; }
      [class='path'] { m/line-width: (@rdz18_min / 4 + 2); }
      [class='major_rail'] { m/line-width: (4 + 3); }
      [class='minor_rail'] { m/line-width: (4 + 3); }
    }
  }
}


// ---- Fill ----------------------------------------------------

#road::fill[class='motorway'][zoom>=8],
#tunnel[class='motorway'][zoom>=10],
#bridge::fill[class='motorway'][zoom>=10] {
  ['mapnik::geometry_type'=2] {
    f/line-color: @motorway_fill;
    f/line-cap: round;
    f/line-join: round;
    [zoom=8] { f/line-width: @rdz08_maj; }
    [zoom=9] { f/line-width: @rdz09_maj; }
    [zoom=10] { f/line-width: @rdz10_maj; }
    [zoom=11] { f/line-width: @rdz10_maj; }
    [zoom=11] { f/line-width: @rdz11_maj; }
    [zoom=12] { f/line-width: @rdz12_maj; }
    [zoom=13] { f/line-width: @rdz13_maj; }
    [zoom=14] { f/line-width: @rdz14_maj; }
    [zoom=15] { f/line-width: @rdz15_maj; }
    [zoom=16] { f/line-width: @rdz16_maj; }
    [zoom=17] { f/line-width: @rdz17_maj; }
    [zoom>17] { f/line-width: @rdz18_maj; }
  }
}

#road::fill[class='motorway_link'][zoom>=9],
#tunnel[class='motorway_link'][zoom>=10],
#bridge::fill[class='motorway_link'][zoom>=10] {
  ['mapnik::geometry_type'=2] {
    f/line-color: mix(@motorway_fill,@main_fill,50%);
    f/line-cap: round;
    f/line-join: round;
    [zoom=11] { f/line-width: @rdz11_maj / 2; }
    [zoom=12] { f/line-width: @rdz12_maj / 2; }
    [zoom=13] { f/line-width: @rdz13_maj / 2; }
    [zoom=14] { f/line-width: @rdz14_maj / 2; }
    [zoom=15] { f/line-width: @rdz15_maj / 2; }
    [zoom=16] { f/line-width: @rdz16_maj / 2; }
    [zoom=17] { f/line-width: @rdz17_maj / 2; }
    [zoom>17] { f/line-width: @rdz18_maj / 2; }
  }
}

#road::fill[class='main'][zoom>=11],
#tunnel[class='main'][zoom>=11],
#bridge::fill[class='main'][zoom>=11] {
  ['mapnik::geometry_type'=2] {
    f/line-color: @main_fill;
    f/line-cap: round;
    f/line-join: round;
    [zoom=11] { f/line-width: @rdz11_med; }
    [zoom=12] { f/line-width: @rdz12_med; }
    [zoom=13] { f/line-width: @rdz13_med; }
    [zoom=14] { f/line-width: @rdz14_med; }
    [zoom=15] { f/line-width: @rdz15_med; }
    [zoom=16] { f/line-width: @rdz16_med; }
    [zoom=17] { f/line-width: @rdz17_med; }
    [zoom>17] { f/line-width: @rdz18_med; }
  }
  ['mapnik::geometry_type'=3] {
    f/polygon-fill: @main_fill;
  }
}
#road::fill[class='main'][zoom>=11] {
  ['mapnik::geometry_type'=1] {
    f/marker-allow-overlap: true;
    f/marker-ignore-placement: true;
    f/marker-fill: @main_fill;
    f/marker-line-opacity: 0;
    [zoom=11] { f/marker-width: @rdz11_med * 1.8; }
    [zoom=12] { f/marker-width: @rdz12_med * 1.8; }
    [zoom=13] { f/marker-width: @rdz13_med * 1.8; }
    [zoom=14] { f/marker-width: @rdz14_med * 1.8; }
    [zoom=15] { f/marker-width: @rdz15_med * 1.8; }
    [zoom=16] { f/marker-width: @rdz16_med * 1.8; }
    [zoom=17] { f/marker-width: @rdz17_med * 1.8; }
    [zoom>17] { f/marker-width: @rdz18_med * 1.8; }
  }
}

#road::fill[class='street'][zoom>=14],
#tunnel[class='street'][zoom>=12],
#bridge::fill[class='street'][zoom>=12] {
  ['mapnik::geometry_type'=2] {
    f/line-color: @road_fill;
    f/line-cap: round;
    f/line-join: round;
    [zoom=14] { f/line-width: @rdz14_min; }
    [zoom=15] { f/line-width: @rdz15_min; }
    [zoom=16] { f/line-width: @rdz16_min; }
    [zoom=17] { f/line-width: @rdz17_min; }
    [zoom>17] { f/line-width: @rdz18_min; }
  }
  ['mapnik::geometry_type'=3] {
    f/polygon-fill: @road_fill;
  }
}
#road::fill[class='street'][zoom>=14] {
  ['mapnik::geometry_type'=1] {
    f/marker-allow-overlap: true;
    f/marker-ignore-placement: true;
    f/marker-fill: @road_fill;
    f/marker-line-opacity: 0;
    [zoom=14] { f/marker-width: @rdz14_min * 1.8; }
    [zoom=15] { f/marker-width: @rdz15_min * 1.8; }
    [zoom=16] { f/marker-width: @rdz16_min * 1.8; }
    [zoom=17] { f/marker-width: @rdz17_min * 1.8; }
    [zoom>17] { f/marker-width: @rdz18_min * 1.8; }
  }
}

#bridge::fill[class='major_rail'][zoom>=13],
#bridge::fill[class='minor_rail'][zoom>=15] {
  ['mapnik::geometry_type'=2] {
    m/line-color: @land;
    [zoom=13] { m/line-width: 0.8 + 1; }
    [zoom=14] { m/line-width: 1 + 1; }
    [zoom=15] { m/line-width: 1.5 + 1; }
    [zoom=16] { m/line-width: 2 + 1; }
    [zoom=17] { m/line-width: 3 + 2; }
    [zoom>17] { m/line-width: 4 + 2; }
  }
}

#road::fill[class='major_rail'][zoom>=13],
#road::fill[class='minor_rail'][zoom>=15],
#tunnel[class='major_rail'][zoom>=13],
#tunnel[class='minor_rail'][zoom>=15],
#bridge::fill[class='major_rail'][zoom>=13],
#bridge::fill[class='minor_rail'][zoom>=15] {
  ['mapnik::geometry_type'=2] {
    f/line-color: @rail_line;
    f/line-dasharray: 1, 2;
    [zoom>=16] { f/line-dasharray: 1, 2; }
    [zoom=13] { f/line-width: 0.8; }
    [zoom=14] { f/line-width: 1; }
    [zoom=15] { f/line-width: 1.5; }
    [zoom=16] { f/line-width: 2; }
    [zoom>16] { f/line-width: 3; }
  }
}

#tunnel[class='major_rail'][zoom>=13]['mapnik::geometry_type'=2],
#tunnel[class='minor_rail'][zoom>=15]['mapnik::geometry_type'=2] {
  f/line-color: #000;
}

// ---- Level Crossings ------------------------------------------------

#road::marker[zoom>=16] {
  ['mapnik::geometry_type'=1][class='level_crossing'] {
    marker-file: url(img/icon/level-crossing.svg);
    marker-allow-overlap: true;
    marker-ignore-placement: true;
    marker-placement: point;
    [zoom=16] { marker-transform: "scale(0.6)"; }
    [zoom=17] { marker-transform: "scale(1)"; }
    [zoom>17] { marker-transform: "scale(1.4)"; }
  }
}

// ---- One-way Arrows -------------------------------------------------

// These are drawn on the acutal road layers to ensure correct ordering
// of arrows on bridges & tunnels.
#road::fill,
#bridge::fill,
#tunnel {
  ['mapnik::geometry_type'=2][zoom>=16][oneway=1] {
    [class='motorway_link'],
    [class='main'],
    [class='street'],
    [class='street_limited'] {
      marker-file: url(img/icon/oneway.svg);
      marker-allow-overlap: true;
      marker-ignore-placement: true;
      marker-placement:line;
      marker-max-error: 0.5;
      marker-spacing: 200;
      [zoom=16] { marker-transform: "scale(0.75)"; }
      [zoom=17] { marker-transform: "scale(1)"; }
      [zoom>17] { marker-transform: "scale(1.25)"; }
    }
  }
}

/**/