toggleFilterChild = (event) ->
  event.preventDefault()

  $target = $(event.target)
  $target.toggleClass('active')

  $childList = $target.parent().find('ul')
  $childList.stop().slideToggle()

setupFiltersConcertina = ->
  $filtersList = $('.home-map-filters > ul')
  $filtersListItems = $filtersList.find('> li')

  $filtersListItems.find('ul').stop()
  $filtersListItems.on('click', '> a', toggleFilterChild)

setupSearchBar = ->
  relatedEls = [$('.home-parent'), $('.home-map'), $('.btn-map-download')]
  new ProtectedPlanet.Search.Bar(
    $('.search-bar'),
    $('.icon.search'),
    {relatedEls: relatedEls}
  )

ready = ->
  new ProtectedPlanet.Map($('#map')).render()
  new ProtectedPlanet.Dropdown($('.btn-map-download'), $('.download-type-dropdown'))

  setupSearchBar()
  setupFiltersConcertina()

$(document).ready(ready)
$(document).on('page:load', ready)
