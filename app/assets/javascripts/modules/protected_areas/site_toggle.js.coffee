define('site_toggle', [], ->
  class SiteToggle
    @initialize: (@$button, @$tabContainer) ->
      #check whether the show/hide button should be shown
      #add click event handler for the show/hide button
      @_checkButton()
      @_addEventListeners()

    @resetSiteToggle: =>
      @_resetToggle()

    @_addEventListeners: ->
      @$button.on('click', (e) =>
        $clicked = $(e.target)
        buttonState = $clicked.data('state')
        $currentTab = @_getCurrentTab()

        @_updateButtonStyling(buttonState)
        @_updateKey(buttonState, $currentTab)
        @_updateMap(buttonState, $currentTab)
      )

    @_checkButton: ->
      currentWDPAIDs = @_getCurrentWDPAIDs()

      if currentWDPAIDs.length > 1
        @$button.removeClass('u-hide')
      else
        @$button.addClass('u-hide')

    @_getCurrentTab: ->
      @$tabContainer.find('.js-tab-content:not(.u-hide)')

    @_getCurrentWDPAIDs: =>
      $currentTab = @_getCurrentTab()
      currentWDPAIDs = $currentTab.data("wdpa-ids")

    @_updateButtonStyling: (buttonState) ->
      #update the icon and text for the button depending on whether it is show or hide
      if(buttonState == 'hide')
        @$button.data('state', 'show')
        @$button.text('Show')
        @$button.addClass('button--show')
      else
        @$button.data('state', 'hide')
        @$button.text('Hide')
        @$button.removeClass('button--show')

    @_updateKey: (buttonState, $currentTab) ->
      #show or hide the items in the key
      if(buttonState == 'hide')
        keyItems = $currentTab.find('.js-key-item:not(:first)')

        $.each(keyItems, (index, val) ->
          $(val).addClass('key--hidden')
        )

      else
        keyItems = $currentTab.find('.js-key-item')

        $.each(keyItems, (index, val) ->
          $(val).removeClass('key--hidden')
        )

    @_updateMap: (buttonState, $currentTab) ->
      #show or hide geometries on the map
      geoArray = []

      if(buttonState == 'hide')
        geoArray.push($currentTab.data("wdpa-ids")[0])
      else
        geoArray = $currentTab.data("wdpa-ids")

      window.ProtectedPlanet.Map.object.updateMap(geoArray)

    @_resetToggle: () ->
      #reset the button and key to the original state
      #the update of the map is handled in protected_areas/base
      $currentTab = @_getCurrentTab()

      @_checkButton()
      @_updateButtonStyling('show')
      @_updateKey('show', $currentTab)

  return SiteToggle
)
