initialiseProtectedCoverageViz = ->
  $vizContainer = $('#protected-coverage-viz')

  return false if $vizContainer.length == 0 or not Modernizr.svg?
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
    annularSectorGenerator data, el, 160, 160

ready = ->
  new ProtectedPlanet.Map($('#map'), ProtectedPlanet.ProtectedAreaMap).render()
  new ProtectedPlanet.PageInitialiser()
  initialiseProtectedCoverageViz()

$(document).ready(ready)
$(document).on('page:load', ready)
