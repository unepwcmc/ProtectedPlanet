$(document).ready( ->
  require(['pagination', 'dropdown'], (Pagination, Dropdown) ->
    new Pagination($('.search-grid'), '.result')
    new Dropdown $('.btn-search-download')
  )
)
