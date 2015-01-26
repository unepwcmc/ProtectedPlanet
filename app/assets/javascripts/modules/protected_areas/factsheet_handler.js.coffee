define('factsheet_handler', [], ->
  class FactsheetHandler
    _isEllipsed = ($el) ->
      $el[0].offsetWidth < $el[0].scrollWidth

    constructor: (@$factsheetEl) ->
      @detectEllipsed()
      @addEventListeners()

    addEventListeners: ->
      @$factsheetEl.find('.key-records > .ellipsed').click( (ev) ->
        left = $(@).find('p')
        right = $(@).find('strong')

        left.toggleClass('hidden-record')
        right.toggleClass('full-record')
      )

      @$factsheetEl.find('.open-details-anchor').click( (ev) ->
        $('.data-completion-info').slideToggle()
        $(this).find('i').toggleClass('fa-chevron-down fa-chevron-up')

        ev.preventDefault()
      )


    detectEllipsed: ->
      @$factsheetEl.find('li > strong').each( ->
        if _isEllipsed($(this))
          $(this).parent('li').addClass('ellipsed')
      )



  return FactsheetHandler
)
