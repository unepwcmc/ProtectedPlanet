define('expandable_section', [], ->
  MAIN_SELECTOR = ".js-expandable-section"

  class ExpandableSection
    @initialize: ($expandableSectionsEl) ->
      new ExpandableSection($expandableSectionsEl).initialize()

    constructor: (@$expandableSectionsEl) ->

    initialize: ->
      @$expandableSectionsEl.each( (i, sectionEl) =>
        @enableToggling($(sectionEl))
        @openIfInPath($(sectionEl)) if $(sectionEl).attr("id")
      )

    enableToggling: ($sectionEl) ->
      $switchEls = $sectionEl.find(".js-switch")
      $targetEls = $sectionEl.find(".js-target")

      $sectionEl.find(".js-trigger").first().click( (ev) ->
        $switchEls.each( (i, switchEl) ->
          $switchEl = $(switchEl)
          isDropdownSwitch = $switchEl.parent().hasClass('js-dropdown')
          isDirectChild = $switchEl.closest(MAIN_SELECTOR).is($sectionEl)

          if(isDirectChild and not isDropdownSwitch)
            $switchEl.toggleClass("is-open is-closed")
        )

        $targetEls.each( (i, targetEl) ->
          $targetEl = $(targetEl)
          isDropdownTarget = $targetEl.parent().hasClass('js-dropdown')
          isDirectChild = $targetEl.closest(MAIN_SELECTOR).is($sectionEl)

          if(isDirectChild and not isDropdownTarget)
            $targetEl.toggleClass("u-hide")
        )
      )

    openIfInPath: ($sectionEl) ->
      if(window.location.hash.split("#")[1] == $sectionEl.attr("id"))
        $sectionEl.find(".js-trigger").first().click()
)


