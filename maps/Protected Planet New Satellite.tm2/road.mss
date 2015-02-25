// -- roads ---------------------------------

#bridge { opacity: .5; }
#road { opacity:.45; }
#tunnel { opacity: 0.13; }

#bridge,
#road[zoom>7],
#tunnel {
  ['mapnik::geometry_type'=2] {
    line-cap: round;
    line-join: round;
    line-gamma: 1.2;
    line-color: @road_fill;
    line-width: 1;
    [class='motorway'] {
      line-width:1;
      [zoom>12] { line-width: 1.5; }
      [zoom=15] { line-width: 3; }
      [zoom=16] { line-width: 6; }
      [zoom=17] { line-width: 8; }
      [zoom>17] { line-width: 12; }
    }
    [class='motorway_link'] {
      line-width: .5;
      [zoom=12] { line-width: .5; }
      [zoom=13] { line-width: .75; }
      [zoom=14] { line-width: 1; }
      [zoom=15] { line-width: 2; }
      [zoom=16] { line-width: 3; }
      [zoom=17] { line-width: 4; }
      [zoom>17] { line-width: 6; }
    }
    [class='main'] {
      line-width: .25;
      line-color: @road_fill;
      [zoom=12] { line-width: .5; }
      [zoom=13] { line-width: .75; }
      [zoom=14] { line-width: 1; }
      [zoom=15] { line-width: 2; }
      [zoom=16] { line-width: 3; }
      [zoom=17] { line-width: 6; }
      [zoom>17] { line-width: 10; }
    }
    [class='street'],
    [class='street_limited'] {
      line-width: .1;
      [zoom=14] { line-width: .5; }
      [zoom=15] { line-width: 1; }
      [zoom=16] { line-width: 3; }
      [zoom=17] { line-width: 6; }
      [zoom>=18] { line-width: 10; }
    }
    [class='street_limited'] {
      line-dasharray: 6, 2;
      line-cap: butt;
    }
    [zoom>15][class='major_rail'],[zoom>15][class='minor_rail'] {
      line-color: @road_fill;
      line-cap: butt;
      line-dasharray:2,2;
      [zoom=16] { line-width: 2; }
      [zoom=17] { line-width: 3; }
      [zoom=18] { line-width: 4; }
      [zoom>18] { line-width: 5; }
    }
    [class='path'] {
      line-width:1.5;
      line-dasharray: 2,2;
      line-cap: butt;
    }
  }
}

// one way arrows

#road,
#bridge,
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
      marker-fill: #000;
      [zoom=16] { marker-transform: "scale(0.75)"; }
      [zoom=17] { marker-transform: "scale(1)"; }
      [zoom>17] { marker-transform: "scale(1.25)"; }
    }
  }
}

// =====================================================================
// ROAD LABELS
// =====================================================================

// highway shield

#road_label[class='motorway'][reflen>=1][reflen<=6],
#road_label[class='main'][reflen>=1][reflen<=6] {
  shield-name: "[ref]";
  shield-size: 9;
  shield-face-name: @sans_bold;
  shield-fill: #000;
  shield-spacing: 200;
  shield-avoid-edges: true;
  shield-min-distance: 50;
  shield-file: url('img/shield/generic-sm-[reflen].svg');
  [zoom>14] {
    shield-spacing: 400;
    shield-min-distance: 60;
    shield-size: 11;
    shield-file: url('img/shield/generic-md-[reflen].svg');
  }
}

// regular labels
#road_label {
  // Longer roads get a label earlier as they are likely to be more
  // important. This especially helps label density in rural/remote areas.
  // This z14 filter is *not* redundant to logic in SQL queries. Because z14
  // includes all data for z14+ via overzooming, the streets included in a
  // z14 vector tile include more features than ideal for optimal performance.
  [class='motorway'][zoom>=12],
  [class='main'][zoom>13][len>3000],
  [class='main'][zoom>14][len>1000],
  [class='main'][zoom>15],
  [class='street'][zoom>=15][len>1000],
  [class='street'][zoom>16],
  [class='street_limited'][zoom>16] {
    text-avoid-edges: true;
    text-transform: uppercase;
    text-name: @name;
    text-character-spacing: 0.25;
    text-placement: line;
    text-face-name: @sans;
    text-fill: @place_text;
    text-size: 8;
    text-halo-fill: fadeout(@place_halo,93);
    text-halo-radius: 2;
    text-halo-rasterizer: fast;
    text-min-distance: 200; // only for labels w/ the same name
    [zoom>=14] { text-size: 9; }
    [zoom>=16] { text-size: 11; }
    [zoom>=18] { text-size: 12; }
    [class='motorway'],
    [class='main'] {
      [zoom>=14] { text-size: 10; }
      [zoom>=16] { text-size: 11; }
      [zoom>=17] { text-size: 12; }
      [zoom>=18] { text-size: 14; }
    }
  }
}

// less prominent labels for service + paths
#road_label[zoom>=16][class='path'] {
    text-avoid-edges: true;
    text-name: @name;
    text-character-spacing: 0.25;
    text-placement: line;
    text-face-name: @sans;
    text-fill: lighten(@place_text,10);
    text-size: 9;
    text-halo-fill: fadeout(@place_halo,90);
    text-halo-radius: 1.5;
    text-halo-rasterizer: fast;
    text-min-distance: 200; // only for labels w/ the same name
    [zoom>=17] { text-size: 10; }
    [zoom>=18] { text-size: 11; }
}
/**/