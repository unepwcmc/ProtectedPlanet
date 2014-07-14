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
//= require cartodb.core
//= require_tree .

$(document).ready(function() {
  if (!(/dont-show-alpha-notice/.test(document.cookie))) {
    $('.alpha-notice').show();
  }

  $('.alpha-notice .close').on('click', function(event) {
    $('.alpha-notice').remove();
    document.cookie = "dont-show-alpha-notice=true";
  });
});
