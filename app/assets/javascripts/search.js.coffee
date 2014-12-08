DEPENDENCIES = [
  'application', 'jquery', 'modules/dropdown',
  'modules/search/pagination', 'modules/search/sidebar'
]

require(DEPENDENCIES, (app, $, Dropdown, Pagination, Sidebar)->
  new Dropdown(
    $('.btn-search-download'),
    $(".download-type-dropdown[data-download-type='search']")
  )

  new Pagination($('.search-grid ul'), '.result')
  new Sidebar($('.search-map-filters'), {
    relatedEls: [$('.search-parent #map'), $('.search-grid')]
  })
)
