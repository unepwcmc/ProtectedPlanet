define('fullscreen', [], ->
  class Fullscreen
    constructor: (@$button) ->
      @addEventListeners()

    addEventListeners: ->
      @$button.on('click', (e) =>
        $clicked = $(e.currentTarget)
        id = $clicked.data('id')
        type = $clicked.data('type')
        $target = $("[data-id='#{id}-target']")

        if(type == 'expand')
          $target.addClass('fullscreen--active')
          $clicked.addClass('fa-compress')
          $clicked.data('type', 'compress')
        else 
          $target.removeClass('fullscreen--active')
          $clicked.removeClass('fa-compress')
          $clicked.data('type', 'expand')

        window.ProtectedPlanet.Map.object.resizeMap()
      )
)