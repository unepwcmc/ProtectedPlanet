$(document).ready( ->
  $countriesSelect = $('#countries-select')
  return false if $countriesSelect.length == 0

  $countriesSelect.select2(containerCss: {width: '200px'})
  $countriesSelect.on 'change', (ev) ->
    iso = $('.factsheet').data('countryIso')
    iso_to_compare = ev.added.id

    window.location = "/country/#{iso}/compare/#{iso_to_compare}"
)
