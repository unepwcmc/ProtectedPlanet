ready = ->
  initialiser = new PageInitialiser()
  initialiser.initialiseMap($('#map'))
  initialiser.initialiseDownloadModal($('body'))
  initialiser.initialiseAboutModal($('body'))

$(document).ready(ready)
$(document).on('page:load', ready)
