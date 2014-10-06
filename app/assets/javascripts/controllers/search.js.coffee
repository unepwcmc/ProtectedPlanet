ready = ->
  initialiser = new PageInitialiser()
  initialiser.initialiseSearchDownloads($('.download-search'), $('body'))

$(document).ready(ready)
$(document).on('page:load', ready)
