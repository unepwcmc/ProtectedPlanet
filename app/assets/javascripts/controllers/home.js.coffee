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

ready = ->
  new ProtectedPlanet.Map($('#map'), ProtectedPlanet.ProtectedAreaMap).render()
  setupFiltersConcertina()

$(document).ready(ready)
$(document).on('page:load', ready)
