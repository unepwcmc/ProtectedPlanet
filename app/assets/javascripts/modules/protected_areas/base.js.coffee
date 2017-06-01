$(document).ready( ->
  require(['factsheet_handler'], (FactsheetHandler) ->
    new FactsheetHandler($('.factsheet'))
  )

  require(['tabs'], (Tabs) ->
    new Tabs($('.js-tabs-map'))
    new Tabs($('.js-tabs-network'))
  )
)
