$(document).ready( ->
  require(
    ['search_bar', 'autocompletion', 'query_control', 'dropdown', 'map', 'navbar', 'asyncImg',
     'downloads_general', 'downloads_project', 'downloads_search', 'expandable_section'],
    (SearchBar, Autocompletion, QueryControl, Dropdown, Map, Navbar, asyncImg,
     DownloadsGeneral, DownloadsProject, DownloadsSearch, ExpandableSection) ->
      bar = new SearchBar()

      $('.search-input').each( ->
        new Autocompletion($(this))
        new QueryControl($(this))
      )

      new Map($('#map')).render()
      Navbar.initialize()

      $('.js-download-btn').each (i, el) -> new Dropdown($(el))

      $('.js-sortable-table').tablesorter(
        cssAsc: 'is-sorted-asc'
        cssDesc: 'is-sorted-desc'
      )

      if $expandableSections = $('.expandable-section')
        ExpandableSection.initialize($expandableSections)

      asyncImg()

      $downloadBtns = [
        $(".download-type-dropdown[data-download-type='general'] a")
        $(".download-type-dropdown[data-download-type='search'] a")
        $(".download-type-dropdown[data-download-type='project'] a")
      ]

      return false if $downloadBtns.length == 0

      $downloadBtns.forEach( ($btn) ->
        $btn.on('click', (e) ->
          # skip standard links
          return unless $(@).data('type')

          dropdown.hide()

          button = $(@)
          e.preventDefault()

          list = button.parents('ul')

          DOWNLOADERS =
            'general': DownloadsGeneral
            'project': DownloadsProject
            'search': DownloadsSearch

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
