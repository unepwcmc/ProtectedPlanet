$(document).ready( ->
  require(['pagination', 'dropdown'], (Pagination, Dropdown) ->
    $searchGridEl = $('.search-grid')
    $filterBarEl = $('.filter-bar')
    new Pagination($searchGridEl, '.result')
    new Dropdown $('.btn-search-download')


    if $searchGridEl.length > 0 and $filterBarEl.length > 0
      searchGridTop = $searchGridEl.offset().top
      $(document).on('scroll', ->
        if($(this).scrollTop() >= searchGridTop)
          $filterBarEl.css(top: "3%", height: "90%")
        else
          $filterBarEl.css(top: "initial", height: "80%")
      )
  )
)
