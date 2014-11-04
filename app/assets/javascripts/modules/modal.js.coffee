class @Modal
  @overlayTemplate: '<div class="total-overlay"><div>'

  constructor: (@$container) ->
    @addOverlay()
    @render()

  render: (template) ->
    $template = $((template || @constructor.template).call())
    @$container.html($template)
    @bindCloseFunctionality()

  addOverlay: ->
    @$overlay = $(@constructor.overlayTemplate)
    $('body').append(@$overlay)

  bindCloseFunctionality: ->
    $closeModalBtn = @$container.find('#close-modal')
    for $el in [@$overlay, $closeModalBtn]
      $el.on('click', (ev) =>
        @hide()
        ev.preventDefault()
      )

  find: (selector) ->
    @$container.find(selector)

  show: ->
    @$container.addClass('opened')
    @$overlay.addClass('visible')

  hide: ->
    @$container.removeClass('opened')
    @$overlay.removeClass('visible')
