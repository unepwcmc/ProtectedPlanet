DEPENDENCIES = [
  'application', 'jquery', 'modules/dropdown',
  'modules/search/pagination'
]

require(DEPENDENCIES, (app, $, Dropdown, Pagination)->
  new Dropdown(
    $('.btn-search-download'),
    $(".download-type-dropdown[data-download-type='search']")
  )

  new Pagination($('.search-grid ul'), '.result')
)
