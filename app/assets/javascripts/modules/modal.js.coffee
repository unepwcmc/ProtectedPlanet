class @Modal
  @overlayTemplate: '<div class="total-overlay"><div>'

  constructor: ($container) ->
    @$el = $(@constructor.template)
    $container.append(@$el)
    @addOverlay($container)

  addOverlay: ($container) ->
    @$overlay = $(@constructor.overlayTemplate)
    $container.append(@$overlay)

  addCloseFunctionality: ->
    $closeModalBtn = @$el.find('#close-modal')
    for $el in [@$overlay, $closeModalBtn]
      $el.on('click', (ev) =>
        @hide()
        ev.preventDefault()
      )

  show: ->
    @$el.addClass('opened')
    @$overlay.addClass('visible')

  hide: ->
    @$el.removeClass('opened')
    @$overlay.removeClass('visible')


