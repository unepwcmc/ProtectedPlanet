window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Downloads ||= {}

class ProtectedPlanet.Downloads.Base
  @CREATION_PATH: '/downloads'
  @POLLING_PATH: '/downloads/poll'
  @POLLING_INTERVAL: 250

  @start: (domain, type, opts={}) ->
    DOWNLOADERS = {
      'general': ProtectedPlanet.Downloads.General
      'project': ProtectedPlanet.Downloads.Project
      'search':  ProtectedPlanet.Downloads.Search
    }
    new DOWNLOADERS[domain](type, opts).start()

  constructor: (@type, @opts={}) ->
    @opts.mainContainer ||= $('#download-modal')
    @generationModal = new DownloadGenerationModal(@opts.mainContainer)

  start: ->
    @submitDownload( (token) =>
      @generationModal.initialiseForm(token)
      @generationModal.show()

      @pollDownload(token, (download) =>
        @generationModal.showDownloadLink(JSON.parse(download.links)[@type])
      )
    )

