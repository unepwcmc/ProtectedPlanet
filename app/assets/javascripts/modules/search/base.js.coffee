$(document).ready( ->
  require(['pagination', 'dropdown'], (Pagination, Dropdown) ->
    new Pagination($('.search-grid ul'), '.result')

    new Dropdown(
      $('.btn-search-download'),
      $(".download-type-dropdown[data-download-type='search']")
    )
  )
)
