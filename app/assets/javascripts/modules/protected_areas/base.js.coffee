$(document).ready( ->
  require(['factsheet_handler'], (FactsheetHandler) ->
    new FactsheetHandler($('.factsheet'))
  )

  require(['tabs'], (Tabs) ->
    new Tabs($('.js-tabs-map'), ($tab, $content) ->
      window.ProtectedPlanet.Map.object.updateMap($tab.data("wdpa-ids"))

      $content.find("[data-wdpa-id]").mouseenter( (ev) ->
        ev.preventDefault()
        $pa = $(@)

        for paGeometry, i in window.ProtectedPlanet.Map.protected_areas
          if i == $pa.data("wdpa-id")
            paGeometry.setStyle({weight: 3, fillOpacity: .8})
          else
            paGeometry.setStyle({weight: 1, fillOpacity: .1})
      )


      $content.find("[data-wdpa-id]").mouseleave( (ev) ->
        ev.preventDefault()
        $pa = $(@)

        for paGeometry in window.ProtectedPlanet.Map.protected_areas
          paGeometry.setStyle({weight: 1, fillOpacity: .6})
      )
    )

    new Tabs($('.js-tabs-network'))
  )
)
