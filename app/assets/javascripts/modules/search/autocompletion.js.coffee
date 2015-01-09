define('autocompletion', [], () ->
  AUTOCOMPLETION_BASE_PATH = '/search/autocomplete'

  class Autocompletion
    constructor: (@$searchInput) ->
      @$parentEl = @$searchInput.closest('div').first()
      @parentElHeight = @$parentEl.outerHeight()
      @$resultsEl = @constructResultsEl()

      @addEventListener()

    addEventListener: ->
      @$searchInput.on('keyup', (ev) =>
        return @hideResults() if ev.which is 27

        term = @$searchInput.val()
        if term.length > 2
          @autocomplete(term)
        else
          @hideResults()
      ).on('blur', =>
        setTimeout(@hideResults, 500)
      )

    autocomplete: (term) =>
      $.get(AUTOCOMPLETION_BASE_PATH, {q: term}, @showResults)

    constructResultsEl: ->
      resultsEl = $('<div class="autocompletion-results"/>')
      @$parentEl.append(resultsEl)

      return resultsEl

    showResults: (results) =>
      @$resultsEl.show()
      @$resultsEl.offset(@parentElOffset())
      @$resultsEl.width(@$parentEl.outerWidth())
      @$resultsEl.html(results)

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
