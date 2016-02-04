define('expandable_section', [], ->
  class ExpandableSection
    @initialize: ($expandableSectionsEl) ->
      new ExpandableSection($expandableSectionsEl).initialize()

    constructor: (@$expandableSectionsEl) ->
      @namespace = 'js-expandable-section'

    initialize: ->
      @$expandableSectionsEl.each( (i, sectionEl) =>
        @enableToggling($(sectionEl))
      )

    enableToggling: ($sectionEl) =>
      $switchEl = $sectionEl.find(".#{@namespace}-switch")
      $targetEl = $sectionEl.find(".#{@namespace}-target")

      $sectionEl.find(".#{@namespace}-trigger").click( (ev) ->
        $switchEl.toggleClass('is-open is-closed')
        $targetEl.toggleClass('u-hide')
      )
)


