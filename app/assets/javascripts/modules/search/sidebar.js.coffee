define(['jquery'], ($) ->
  class Sidebar
    constructor: (@$el, @options) ->
      @$openMapTriggerEl = $('.btn-switch-map')
      @$openGridTriggerEl = $('.btn-switch-grid')

      $('.btn-switch-grid').addClass('active')
      @addEventListeners()

    addEventListeners: ->
      @$openMapTriggerEl.click(@toggleGrid(@$openMapTriggerEl))
      @$openGridTriggerEl.click(@toggleGrid(@$openGridTriggerEl))

    toggleGrid: ($el) =>
      (ev) =>
        return false if $el.hasClass('active')

        [@$openMapTriggerEl, @$openGridTriggerEl].forEach((el) -> el.toggleClass('active'))
        $('.search-map').toggle()
        $('.search-grid').toggle()
        ProtectedPlanet.Map.instance.invalidateSize(true)
        ev.preventDefault()

  return Sidebar
)
