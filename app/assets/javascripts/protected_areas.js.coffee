ready = ->
  initialiser = new PageInitialiser()
  initialiser.initialiseMap('map')
  initialiser.initialiseDownloadModal()

$(document).ready(ready)
$(document).on('page:load', ready)
