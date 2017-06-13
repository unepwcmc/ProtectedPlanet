$(document).ready( ->
  require(['factsheet_handler'], (FactsheetHandler) ->
    new FactsheetHandler($('.factsheet'))
  )

  require(['tabs', 'site_toggle'], (Tabs, SiteToggle) ->

    SiteToggle.initialize($('.js-site-toggle'), $('.js-tabs-map'))

    new Tabs($('.js-tabs-map'), ($tab, $tabContainer = null) ->

      #update the geometry when the tab is changed
      if($tab != null)
        window.ProtectedPlanet.Map.object.updateBounds($tab.data("network-id"))
        window.ProtectedPlanet.Map.object.updateMap($tab.data("wdpa-ids"))
        SiteToggle.resetSiteToggle()

      #add hover effect to the each key and geometry
      if($tabContainer != null)
        $tabContents = $tabContainer.find('.js-tab-content')

        $.each($tabContents, (i, val) ->
          $content = $(val)

          $content.find("[data-wdpa-id]").mouseenter( (ev) ->
            ev.preventDefault()
            $pa = $(@)

            for paGeometry, i in window.ProtectedPlanet.Map.protectedAreas
              if i == $pa.data("wdpa-id")
                paGeometry.setStyle({weight: 3, fillOpacity: .8})
              else
                paGeometry.setStyle({weight: 1, fillOpacity: .1})
          )

          $content.find("[data-wdpa-id]").mouseleave( (ev) ->
            ev.preventDefault()
            $pa = $(@)

            for paGeometry in window.ProtectedPlanet.Map.protectedAreas
              paGeometry.setStyle({weight: 1, fillOpacity: .6})
          )
        )
    )

    new Tabs($('.js-tabs-network'))
  )
)
