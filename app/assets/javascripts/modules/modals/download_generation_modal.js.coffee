class @DownloadGenerationModal extends Modal
  BASE_DOWNLOAD_PATH = '/downloads'

  @template: -> $('#download-modal-template').html()
  @downloadCompleteTemplate: -> $('#download-complete-modal-template').html()

  constructor: ($container) ->
    super($container)

  showDownloadCompleteTemplate: ->
    @render(@constructor.downloadCompleteTemplate)
    @show()

  showDownloadLink: (objectName, type) ->
    @showDownloadCompleteTemplate()

    downloadUrl = "#{BASE_DOWNLOAD_PATH}/#{objectName}?type=#{type}"
    @find('.link-container').html("""
      <a target="_blank" class="btn btn-primary" href="#{downloadUrl}">Download</a>
    """)
