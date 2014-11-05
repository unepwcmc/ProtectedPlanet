class @Modal
  constructor: (@$container) ->
    @$overlay = $('.total-overlay')
    @render()

  render: (template) ->
    $template = $((template || @constructor.template).call())
    @$container.html($template)
    @bindCloseFunctionality()

  bindCloseFunctionality: ->
    $closeModalBtn = @$container.find('.js-close-modal')
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
