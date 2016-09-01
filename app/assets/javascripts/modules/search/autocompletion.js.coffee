define('autocompletion', ['asyncImg'], (asyncImg) ->
  AUTOCOMPLETION_BASE_PATH = '/search/autocomplete'

  class Autocompletion
    constructor: (@$searchInput) ->
      @$resultsEl = @$searchInput
        .closest('.js-search-container')
        .find('.js-autocompletion-results')
      @addEventListener()

    addEventListener: ->
      @$searchInput.on(
        'keyup', _.debounce(@handleKeyup, 300)
      )

    handleKeyup: (ev) =>
      return @hideResults() if ev.which is 27
      return if @term is @$searchInput.val()

      @term = @$searchInput.val()
      if @term.length > 2
        @autocomplete(@term)
      else
        @hideResults()

    autocomplete: (term) =>
      $.get(AUTOCOMPLETION_BASE_PATH, {q: term}, @showResults)

    showResults: (results) =>
      @$resultsEl.html(results)
      @$resultsEl.show()
      asyncImg()

    hideResults: =>
      @$resultsEl.hide()

  return Autocompletion
)
