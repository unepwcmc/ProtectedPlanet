
#admin[zoom>=2] {
  ::lev2[admin_level=2] {
    opacity: 0.8;
    line-join: round;
    line-color: #000;
    [maritime=1] {
      line-color: #026;
      line-opacity: 0.05;
    }
    [zoom>=2] { line-width: 0.4; }
    [zoom>=4] { line-width: 0.8; }
    [zoom>=6] { line-width: 1.2; }
    [zoom>=8] { line-width: 1.8; }
    [zoom>=10] { line-width: 2.2; }
    [zoom>=12] { line-width: 2.6; }
    [zoom>=14] { line-width: 3.0; }
    [zoom>=16] { line-width: 4.0; }
    [disputed=1][zoom<=5] { line-dasharray: 4 , 3; }
    [disputed=1][zoom>=6][zoom<=7] { line-dasharray: 5 , 3; }
    [disputed=1][zoom>=8][zoom<=9] { line-dasharray: 7 , 4; }
    [disputed=1][zoom>=10][zoom<=11] { line-dasharray: 9 , 5; }
    [disputed=1][zoom>=12][zoom<=13] { line-dasharray: 11 , 6; }
    [disputed=1][zoom>=14][zoom<=15] { line-dasharray: 13 , 7; }
    [disputed=1][zoom>=16] { line-dasharray: 15 , 8; }
  }
  ::lev2off[admin_level=2] {
    opacity: 0.5;
    line-join: round;
    line-color: @admin_2;
    line-offset: 1;
    [maritime=1] {
      line-color: #026;
      line-opacity: 0.05;
    }
    [zoom>=2] { line-width: 0.4; }
    [zoom>=4] { line-width: 0.8; }
    [zoom>=6] { line-width: 1.2; }
    [zoom>=8] { line-width: 1.8; }
    [zoom>=10] { line-width: 2.2; }
    [zoom>=12] { line-width: 2.6; }
    [zoom>=14] { line-width: 3.0; }
    [zoom>=16] { line-width: 4.0; }
    [disputed=1][zoom<=5] { line-dasharray: 4 , 3; }
    [disputed=1][zoom>=6][zoom<=7] { line-dasharray: 5 , 3; }
    [disputed=1][zoom>=8][zoom<=9] { line-dasharray: 7 , 4; }
    [disputed=1][zoom>=10][zoom<=11] { line-dasharray: 9 , 5; }
    [disputed=1][zoom>=12][zoom<=13] { line-dasharray: 11 , 6; }
    [disputed=1][zoom>=14][zoom<=15] { line-dasharray: 13 , 7; }
    [disputed=1][zoom>=16] { line-dasharray: 15 , 8; }
  }
  /**/
  ::lev34[admin_level>=3] {
    [admin_level=3] {
      line-color: #000;
      line-opacity: 0.5;
      line-dasharray: 12, 3;
    }
    [admin_level=4] {
      line-color: #000;
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

#marine_label {
  text-name: @name;
  text-face-name: @sans_lt_italic;
  text-fill: #888;
  text-opacity: 0.25;
  text-wrap-before: true;
  [placement = 'point'] {
    text-placement: point;
    text-wrap-width: 50;
  }
  [placement = 'line'] {
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