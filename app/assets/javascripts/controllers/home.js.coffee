ready = ->
  new ProtectedPlanet.Map($('#map'), ProtectedPlanet.ProtectedAreaMap).render()
  new ProtectedPlanet.PageInitialiser()

$(document).ready(ready)
$(document).on('page:load', ready)
