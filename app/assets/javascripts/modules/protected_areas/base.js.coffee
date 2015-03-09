$(document).ready( ->
  require(['factsheet_handler'], (FactsheetHandler) ->
    new FactsheetHandler($('.factsheet'))
  )
)
