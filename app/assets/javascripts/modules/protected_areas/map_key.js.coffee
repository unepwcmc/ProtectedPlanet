define('map_key', [], ->
  class MapKey
    @initialize: (@$tabContent) ->
      @_addEventListeners()

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

          $clicked.text('Uncheck all')
          $clicked.data('toggle-type','hide')
      )

    @_select: (keyItem) ->
      $keyItem = $(keyItem)
      wdpaId = $keyItem.data('wdpa-id')

      $keyItem.addClass('js-active-key-item')
      $keyItem.addClass('key__checkbox--active')

      unless window.ProtectedPlanet.Map.protectedAreas[wdpaId] == undefined
        window.ProtectedPlanet.Map.protectedAreas[wdpaId].setStyle({ fillOpacity: .6, opacity: 1 })

    @_deSelect: (keyItem) ->
      $keyItem = $(keyItem)
      wdpaId = $keyItem.data('wdpa-id')

      $keyItem.removeClass('js-active-key-item')
      $keyItem.removeClass('key__checkbox--active')
      
      unless window.ProtectedPlanet.Map.protectedAreas[wdpaId] == undefined
        window.ProtectedPlanet.Map.protectedAreas[wdpaId].setStyle({ fillOpacity: 0, opacity: 0 })
  
  return MapKey
)
