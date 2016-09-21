define('dismissable', [], ->
  class Dismissable
    @initialize: ($expandableSectionsEl) ->
      new Dismissable($expandableSectionsEl).initialize()

    constructor: (@$dismissableEls) ->

    initialize: ->
      @$dismissableEls.each( (i, dismissableEl) =>
        @dismissOnClick($(dismissableEl))
      )

    dismissOnClick: ($dismissableEl) ->
      $targetEl = $dismissableEl.find(".js-target")

      $dismissableEl.find(".js-trigger").click( (ev) ->
        ev.preventDefault()
        $dismissableEl.addClass('u-hide')
      )
)



