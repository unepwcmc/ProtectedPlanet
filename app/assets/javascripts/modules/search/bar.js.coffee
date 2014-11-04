window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Search ||= {}

class ProtectedPlanet.Search.Bar
  constructor: (@$el, @$triggerEl, @options) ->
    @options ||= {}
    @addEventListeners()

  addEventListeners: ->
    @$triggerEl.click( (ev) =>
      @$el.toggleClass('opened')
      @$triggerEl.toggleClass('opened')
      @options.relatedEls?.forEach(($el) -> $el?.toggleClass('opened'))
      ev.preventDefault()
    )
