define('autocompletion', ['asyncImg'], (asyncImg) ->
  AUTOCOMPLETION_BASE_PATH = '/search/autocomplete'

  class Autocompletion
    constructor: (@$searchInput) ->
      @$parentEl = @$searchInput.closest('div').first()
      @parentElHeight = @$parentEl.outerHeight()
      @$resultsEl = @constructResultsEl()

      @addEventListener()

    addEventListener: ->
      @$searchInput.on(
        'keyup', _.debounce(@handleKeyup, 300)
      ).on(
        'blur', => setTimeout(@hideResults, 500)
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

    constructResultsEl: ->
      resultsEl = $('<div class="autocompletion-results"/>')
      @$parentEl.append(resultsEl)

      return resultsEl

    showResults: (results) =>
      @$resultsEl.show()
      @$resultsEl.offset(@parentElOffset())
      @$resultsEl.width(@$parentEl.width())
      @$resultsEl.html(results)
      asyncImg()

    hideResults: =>
      @$resultsEl.hide()

    parentElOffset: =>
      offset = @$parentEl.offset()

      {
        left: offset.left,
        top: offset.top + @parentElHeight
      }

  return Autocompletion
)
