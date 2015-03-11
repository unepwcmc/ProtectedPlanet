$(document).ready( ->
  require(
    ['search_bar', 'autocompletion', 'query_control', 'dropdown', 'map', 'asyncImg',
     'downloads_general', 'downloads_project', 'downloads_search'],
    (SearchBar, Autocompletion, QueryControl, Dropdown, Map, asyncImg,
     DownloadsGeneral, DownloadsProject, DownloadsSearch) ->
      bar = new SearchBar()

      $('.search-input').each( ->
        new Autocompletion($(this))
        new QueryControl($(this))
      )

      new Map($('#map')).render()

      dropdown = new Dropdown(
        $('.btn-download'),
        $(".download-type-dropdown[data-download-type='general']")
      )

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

  new Konami( () ->
    audio = new Audio('/jingle.mp3')
    audio.play()
    styles = document.styleSheets[document.styleSheets.length-1]
    styles.insertRule('* { font-family: "Comic Sans MS" !important; }',styles.cssRules.length)
  )
)
