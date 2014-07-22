ready = ->
  initialiser = new PageInitialiser()
  initialiser.initialiseMap($('#map'))
  initialiser.initialiseDownloadModal($('body'))
  initialiser.initialiseAboutModal($('body'))
  initialiser.initialiseProtectedCoverageViz($('#protected-coverage-viz'))

$(document).ready(ready)
$(document).on('page:load', ready)
