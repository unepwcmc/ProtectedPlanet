define(['jquery'], ($) ->
  class SearchBar
    constructor: (@options) ->
      @$el = $('.search-bar')
      @$triggerEl = $('.search-button')
      @$inputEl = $('.search-input')
      @options ||= {}

      @addEventListeners()

    addEventListeners: ->
      @$triggerEl.click( (ev) =>
        @$el.slideToggle()
        @$triggerEl.toggleClass('opened')
        @options.relatedEls?.forEach(($el) -> $el?.toggleClass('opened'))
        @$inputEl.focus()
        ev.preventDefault()
      )

  return SearchBar
)
