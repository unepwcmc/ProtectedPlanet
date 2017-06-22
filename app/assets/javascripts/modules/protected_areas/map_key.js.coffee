define('map_key', [], ->
  class MapKey
    @initialize: (@$tabContent) ->
      @_addEventListeners()

    @resetKey: ($tab) =>
      tabContentId = $tab.data('id') + '-content'
      $tabContent = $tab.parents('.js-tabs-map').find("[data-id='#{tabContentId}']")
      keyItems = $tabContent.find('.js-key-item')

      #reset key items
      $.each(keyItems, (i, val) =>
        @_select(val)
      )

      #update key toggle
      $button = $tabContent.find('.js-key-toggle')

      @_setButtonToUncheck($button)

    @_addEventListeners: ->
      #add click event to key item and geometry
      @$tabContent.find('.js-key-item').on('click', (ev) =>
        keyItem = ev.currentTarget

        if($(keyItem).hasClass('js-active-key-item'))
          @_deSelect(keyItem)
        else 
          @_select(keyItem)
      )

      #add click event to uncheck button
      @$tabContent.find('.js-key-toggle').on('click', (ev) =>
        $clicked = $(ev.currentTarget)
        type = $clicked.data('toggle-type')
        $tab = $clicked.parent('.js-tab-content')
        keyItems = $tab.find('.js-key-item')

        if(type == 'hide')

          $.each(keyItems, (i, val) =>
            @_deSelect(val)
          )

          $clicked.text('Check all')
          $clicked.data('toggle-type','show')

        else

          $.each(keyItems, (i, val) =>
            @_select(val)
          )

          @_setButtonToUncheck($clicked)
      )

    @_select: (keyItem) ->
      $keyItem = $(keyItem)
      wdpaId = $keyItem.data('wdpa-id')

      $keyItem.addClass('js-active-key-item key__checkbox--active')

      unless window.ProtectedPlanet.Map.protectedAreas[wdpaId] == undefined
        window.ProtectedPlanet.Map.protectedAreas[wdpaId].setStyle({ fillOpacity: .6, opacity: 1 })

    @_deSelect: (keyItem) ->
      $keyItem = $(keyItem)
      wdpaId = $keyItem.data('wdpa-id')

      $keyItem.removeClass('js-active-key-item key__checkbox--active')
      
      unless window.ProtectedPlanet.Map.protectedAreas[wdpaId] == undefined
        window.ProtectedPlanet.Map.protectedAreas[wdpaId].setStyle({ fillOpacity: 0, opacity: 0 })

    @_setButtonToUncheck: ($button) ->
      $button.text('Uncheck all')
      $button.data('toggle-type','hide')

  return MapKey
)
