define('autocompletion', [], () ->
  AUTOCOMPLETION_BASE_PATH = '/search/autocomplete'

  class Autocompletion
    constructor: (@$searchInput, @$resultsEl) ->
      @addEventListener()

    addEventListener: ->
      @$searchInput.on('keyup', (ev) =>
        term = @$searchInput.val()
        if term.length > 2
          @autocomplete(term)
        else
          @hideResults()
      ).on('blur', =>
        setTimeout(@hideResults, 500)
      )



    autocomplete: (term) =>
      $.get(AUTOCOMPLETION_BASE_PATH, {q: term}, (response) =>
        @$resultsEl.html(response)
        @$resultsEl.show()
      )

    hideResults: =>
      @$resultsEl.hide()


  return Autocompletion
)
