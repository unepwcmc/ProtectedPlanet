window.ProtectedPlanet ||= {}

class ProtectedPlanet.Dropdown
  constructor: (@$triggerEl, @$el, @options) ->
    if @$triggerEl.length is 0 or @$el.length is 0
      return false

    @options ||= {on: 'click'}
    @render()

  render: ->
    @$el.hide()

    @positionEl()
    @addEventListener()

  positionEl: ->
    triggerPosition = @$triggerEl.position()

    @$el.width(@$triggerEl.outerWidth())

    @$el.css('position', @$triggerEl.css('position'))
    @$el.css('top', (triggerPosition.top + @$triggerEl.outerHeight()) )
    @$el.css('left', triggerPosition.left)

  addEventListener: ->
    @$triggerEl.on(@options.on, (event) =>
      @$el.slideToggle()
      event.preventDefault()
    )
