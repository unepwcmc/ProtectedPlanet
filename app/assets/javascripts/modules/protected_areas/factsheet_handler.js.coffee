define('factsheet_handler', [], ->
  class FactsheetHandler
    _isEllipsed = ($el) ->
      $el[0].offsetWidth < $el[0].scrollWidth

    constructor: (@$factsheetEl) ->
      @detectEllipsed()
      @addEventListeners()

    addEventListeners: ->
      @$factsheetEl.find('.ellipsed').click( (ev) ->
        left = $(@).find('p')
        right = $(@).find('strong')

        left.toggleClass('hidden-record')
        right.toggleClass('full-record')
      )

    detectEllipsed: ->
      @$factsheetEl.find('li > strong').each( ->
        if _isEllipsed($(this))
          $(this).parent('li').addClass('ellipsed')
      )



  return FactsheetHandler
)
