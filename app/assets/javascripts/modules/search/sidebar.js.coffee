window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Search ||= {}

class ProtectedPlanet.Search.Sidebar
  constructor: (@$el, @options) ->
    @$openTriggerEl = $('.fixed-sidebar-toggle')
    @$closeTriggerEl = $('.sidebar-toggle')
    @$openMapTriggerEl = $('.btn-switch-map')
    @$openGridTriggerEl = $('.btn-switch-grid')

    $('.btn-switch-map').addClass('active')
    @addEventListeners()

  addEventListeners: ->
    @$openTriggerEl.click(@toggleSidebar(true))
    @$closeTriggerEl.click(@toggleSidebar(false))

    @$openMapTriggerEl.click(@toggleGrid(@$openMapTriggerEl))
    @$openGridTriggerEl.click(@toggleGrid(@$openGridTriggerEl))

  toggleSidebar: (opening) =>
    (ev) =>
      @$el.one('transitionend', =>
        ProtectedPlanet.Map.instance.invalidateSize(true)
        @$openTriggerEl.addClass('opened') unless opening
      )

      @$openTriggerEl.removeClass('opened') if opening
      @$el.toggleClass('closed')
      @options.relatedEls?.forEach( ($relatedEl) -> $relatedEl.toggleClass('opened') )

      ev.preventDefault()

  toggleGrid: ($el) =>
    (ev) =>
      return false if $el.hasClass('active')

      [@$openMapTriggerEl, @$openGridTriggerEl].forEach((el) -> el.toggleClass('active'))
      $('.search-map').slideToggle()
      $('.search-grid').slideToggle()
      ev.preventDefault()
