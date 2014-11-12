// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require modernizr.custom.30580
//= require d3
//= require jquery.infinitescroll
//= require mapbox
//= require leaflet.markercluster
//= require cartodb.core
//= require best_in_place
//= require select2
//= require_tree ./modules/maps
//= require_tree ./modules/search
//= require_tree ./modules
//= require_tree ./modules/modals
//= require_tree ./controllers

var initializeSearchBar = function() {
  new ProtectedPlanet.Search.Bar(
    $('.search-bar'),
    $('.icon.search')
  );
};

var initializeDropdowns = function() {
  new ProtectedPlanet.Dropdown(
    $('.btn-map-download'),
    $(".download-type-dropdown[data-download-type='general']")
  );
  new ProtectedPlanet.Dropdown(
    $('.btn-search-download'),
    $(".download-type-dropdown[data-download-type='search']")
  );
  new ProtectedPlanet.Dropdown(
    $('.btn-search-download'),
    $(".download-type-dropdown[data-download-type='general']")
  );
  $(".project").each( function(i, el) {
    new ProtectedPlanet.Dropdown(
      $(el).find('.btn-project-download'),
      $(el).find(".download-type-dropdown[data-download-type='project']")
    );
  });

  $("#countries-select").select2({
    placeholder: "Select a Country for Comparison",
    width: 'element'
  });
  new ProtectedPlanet.Dropdown(
    $('.btn-add-to-project'),
    $('#add-to-project')
  );
  new ProtectedPlanet.Dropdown(
    $('.btn-add-search-to-project'),
    $('#add-search-to-project')
  );
};


var ready = function() {
  initializeSearchBar();
  initializeDropdowns();
};

$(window).load(ready)
$(document).on('page:load', ready)
