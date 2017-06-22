$(document).ready( ->
  require(['factsheet_handler'], (FactsheetHandler) ->
    new FactsheetHandler($('.factsheet'))
  )

  require(['map'], (Map) ->
    new Map($('#map-connections')).render()
  )

  require(['tabs', 'map_key'], (Tabs, MapKey) ->

    new Tabs($('.js-tabs-map'), ($tab, $tabContainer = null) ->

      #update the geometry when the tab is changed
      if($tab != null)
        window.ProtectedPlanet.Map.object.updateBounds($tab.data("network-id"))
        window.ProtectedPlanet.Map.object.updateMap($tab.data("wdpa-ids"))
        MapKey.resetKey($tab)

      #add event listeners to items in the map key
      if($tabContainer != null)

        $tabContents = $tabContainer.find('.js-tab-content')

        $.each($tabContents, (i, val) ->
          $tabContent = $(val)

          MapKey.initialize($tabContent)
        )
    )

    new Tabs($('.js-tabs-network'))
  )
)
