initialiseFilterDownloads = ->
  $downloadBtns = $('nav.sub-nav .download-type-dropdown a')
  return false if $downloadBtns.length == 0

  $downloadBtns.on('click', (e) ->
    e.preventDefault()

    button = $(e.target)
    ProtectedPlanet.Search.Download.start(button.data('type'))
  )

getParameter = (name) ->
  name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]")
  regex = new RegExp("[\\?&]" + name + "=([^&#]*)")
  results = regex.exec(location.search)
  return if results == null then "" else results[1].replace(/\+/g, " ")

toggleFilterChild = (event) ->
  event.preventDefault()

  $target = $(event.target)
  $target.toggleClass('active')

  $childList = $target.parent().find('ul')
  $childList.stop().slideToggle()

setupFiltersConcertina = ->
  $filtersList = $('.home-map-filters > ul')
  $filtersListItems = $filtersList.find('> li')

  $filtersListItems.each( (index, element) ->
    $element = $(element)
    filterName = $element.data().attribute

    $element.find('> ul').show() if getParameter(filterName)
    $element.on('click', '> a', toggleFilterChild)
  )

ready = ->
  new ProtectedPlanet.Map($('#map')).render()

  setupFiltersConcertina()
  initialiseFilterDownloads()

$(document).ready(ready)
$(document).on('page:load', ready)
