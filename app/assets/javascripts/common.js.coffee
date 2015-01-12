$(document).ready( ->
  require(['search_bar', 'autocompletion', 'dropdown', 'map', 'asyncImg'], (SearchBar, Autocompletion, Dropdown, Map, asyncImg) ->
    bar = new SearchBar()

    $('.search-input').each( -> new Autocompletion($(this)))

    new Map($('#map')).render()

    new Dropdown(
      $('.btn-download'),
      $(".download-type-dropdown[data-download-type='general']")
    )

    asyncImg()
  )

  require(
    ['downloads_general', 'downloads_project', 'downloads_search'],
    (DownloadsGeneral, DownloadsProject, DownloadsSearch) ->
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

          button = $(@)
          e.preventDefault()

          list = button.parents('ul')

          DOWNLOADERS =
            'general': DownloadsGeneral
            'project': DownloadsProject
            'search': DownloadsSearch

          downloader = new DOWNLOADERS[list.data('download-type')]
          downloader.start(
            button.data('type'),
            {itemId: list.data('item-id')}
          )
        )
      )
  )

  $('.explore .search-input').focus()
)
