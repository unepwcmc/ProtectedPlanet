require(['search_bar', 'dropdown'], (SearchBar, Dropdown) ->
  new SearchBar()

  new Dropdown(
    $('.btn-download'),
    $(".download-type-dropdown[data-download-type='general']")
  )
)
