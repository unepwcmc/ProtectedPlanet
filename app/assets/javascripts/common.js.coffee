$(document).ready( ->
  require(
    ['autocompletion', 'query_control', 'dropdown', 'map', 'navbar', 'asyncImg',
     'downloads_general', 'downloads_search', 'downloads_protected_area',
     'expandable_section', 'dismissable', 'resizable'],
    (Autocompletion, QueryControl, Dropdown, Map, Navbar, asyncImg,
     DownloadsGeneral, DownloadsSearch, DownloadsProtectedArea,
     ExpandableSection, Dismissable, Resizable) ->
      $('.js-search-input').each( ->
        new Autocompletion($(this))
        new QueryControl($(this))
      )

      new Map($('#map')).render()
      new Map($('#map-mobile')).render()
      Navbar.initialize()

      $('.js-download-btn').each (i, el) -> new Dropdown($(el))

      $('.js-sortable-table').tablesorter(
        cssAsc: 'is-sorted-asc'
        cssDesc: 'is-sorted-desc'
      )

      if $expandableSections = $('.js-expandable-section')
        ExpandableSection.initialize($expandableSections)

      if $dismissableEls = $('.js-dismissable')
        Dismissable.initialize($dismissableEls)

      if $resizableEls = $('.js-resizable')
        Resizable.initialize($resizableEls)

      asyncImg()

      $downloadBtns = [
        $(".download-type-dropdown[data-download-type='general'] a")
        $(".download-type-dropdown[data-download-type='search'] a")
        $(".download-type-dropdown[data-download-type='protected_area'] a")
      ]

      return false if $downloadBtns.length == 0

      $downloadBtns.forEach( ($btn) ->
        $btn.on('click', (e) ->
          # skip standard links
          return unless $(@).data('type')

          button = $(@)
          e.preventDefault()

          list = button.parents('.js-target')

          DOWNLOADERS =
            'general': DownloadsGeneral
            'search': DownloadsSearch
            'protected_area': DownloadsProtectedArea

          downloader = new DOWNLOADERS[list.data('download-type')](
            button.data('type'),
            {itemId: list.data('item-id')}
          )

          downloader.start()
        )
      )
  )

  $('.explore .search-input').focus()
)
