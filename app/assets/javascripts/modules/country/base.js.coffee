require(['annular_sector'], (annularSector)->
  $vizContainer = $('#protected-coverage-viz')
  return false if $vizContainer.length == 0

  $vizContainer.find('.viz').each (idx, el) ->
    value = $(el).attr('data-value')
    return if typeof +value isnt 'number' or +value is isNaN
    data = [
      {
        value: value
        color: $(el).attr('data-colour')
      }
      {
        value: 100 - value
        color: '#d2d2db'
        is_background: true
      }
    ]

    annularSector data, el, 160, 160
)

$countriesSelect = $('#countries-select')
return false if $countriesSelect.length == 0

$countriesSelect.select2(containerCss: {width: '200px'})
$countriesSelect.on 'change', (ev) ->
  iso2 = ev.added.id
  window.location = "/country/AR/compare/#{iso2}"
