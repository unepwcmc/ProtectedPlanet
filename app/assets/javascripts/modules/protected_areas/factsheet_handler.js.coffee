define('factsheet_handler', [], ->
  class FactsheetHandler
    _isEllipsed = ($el) ->
      $el[0].offsetWidth < $el[0].scrollWidth

    constructor: (@$factsheetEl) ->
      @addEventListeners()

    addEventListeners: ->
      @$factsheetEl.find('li').hover( (ev) ->
        right = $(@).find('strong')
        if _isEllipsed(right)
          left = $(@).find('p')
          left.addClass('hidden-record')
          right.addClass('full-record')
      , (ev) ->
        right = $(@).find('strong')
        left = $(@).find('p')
        left.removeClass('hidden-record')
        right.removeClass('full-record')
      )


  return FactsheetHandler
)
