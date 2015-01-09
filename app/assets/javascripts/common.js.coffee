$(document).ready( ->
  require(['search_bar', 'autocompletion', 'dropdown', 'map'], (SearchBar, Autocompletion, Dropdown, Map) ->
    bar = new SearchBar()

    bar.$inputEl.each( ->
      new Autocompletion($(this))
    )

    new Map($('#map')).render()

    new Dropdown(
      $('.btn-download'),
      $(".download-type-dropdown[data-download-type='general']")
    )
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
)
