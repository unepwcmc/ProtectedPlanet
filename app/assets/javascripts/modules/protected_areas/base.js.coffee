$(document).ready( ->
  require(['factsheet_handler'], (FactsheetHandler) ->
    new FactsheetHandler($('.factsheet'))
  )

  require(['tabs'], (Tabs) ->
    new Tabs($('.js-tabs-map'), ($tab) ->
      console.log($tab.data("wdpa-ids"))
    )
    new Tabs($('.js-tabs-network'))
  )
)
