require(['search_bar', 'dropdown', 'map'], (SearchBar, Dropdown, Map) ->
  new SearchBar()

  new Map($('#map')).render()

  new Dropdown(
    $('.btn-download'),
    $(".download-type-dropdown[data-download-type='general']")
  )
)
