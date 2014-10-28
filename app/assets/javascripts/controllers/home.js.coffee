ready = ->
  new ProtectedPlanet.Map($('#map'), ProtectedPlanet.ProtectedAreaMap).render()

$(document).ready(ready)
$(document).on('page:load', ready)
