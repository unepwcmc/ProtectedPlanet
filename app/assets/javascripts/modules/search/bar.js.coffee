define('search_bar', [], () ->
  class SearchBar
    constructor: (@options) ->
      @$el = $('.search-bar')
      @$triggerEl = $('.search-button')
      @$inputEl = $('.search-input')
      @$autocompletionEl = $('.autocompletion-results')
      @options ||= {}

      @addEventListeners()

    addEventListeners: ->
      @$triggerEl.click( (ev) =>
        @$el.stop()
        @$el.slideToggle()
        @$triggerEl.toggleClass('opened')
        @options.relatedEls?.forEach(($el) -> $el?.toggleClass('opened'))
        @$inputEl.focus()
        ev.preventDefault()
      )

  return SearchBar
)
