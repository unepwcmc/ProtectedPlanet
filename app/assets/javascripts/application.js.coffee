DEPENDENCIES = [
  'jquery', 'modules/search/bar', 'modules/map',
  'modules/downloads/base', 'modules/downloads/general',
  'modules/downloads/project', 'modules/downloads/search',
]

require(DEPENDENCIES, ($, SearchBar, Map, DownloadsBase, DownloadsGeneral, DownloadsProject, DownloadsSearch)->
  initializeDownloadButtons = ->
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

  new SearchBar()
  new Map($('#map')).render()
  initializeDownloadButtons()
)
