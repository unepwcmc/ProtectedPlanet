define('query_control', [], () ->
  class QueryControl
    constructor: ($inputEl) ->
      $inputEl.parent('form').submit( (ev) =>
        if $inputEl.val() == ''
          ev.preventDefault()
      )

  return QueryControl
)
