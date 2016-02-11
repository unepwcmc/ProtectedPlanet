define('expandable_section', [], ->
  class ExpandableSection
    @initialize: ($expandableSectionsEl) ->
      new ExpandableSection($expandableSectionsEl).initialize()

    constructor: (@$expandableSectionsEl) ->

    initialize: ->
      @$expandableSectionsEl.each( (i, sectionEl) =>
        @enableToggling($(sectionEl))
      )

    enableToggling: ($sectionEl) ->
      $switchEl = $sectionEl.find(".js-switch")
      $targetEl = $sectionEl.find(".js-target")

      $sectionEl.find(".js-trigger").click( (ev) ->
        $switchEl.toggleClass('is-open is-closed')
        $targetEl.toggleClass('u-hide')
      )
)


