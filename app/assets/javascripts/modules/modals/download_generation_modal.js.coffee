class @DownloadGenerationModal extends Modal
  BASE_DOWNLOAD_PATH = '/downloads'

  @template: """
    <div id="close-modal">X</div>
    <h2>Generating personalised dataset…</h2>

    <p>
      Saved search results can take a while to process in to your
      chosen format for download. Pop your email in below to get a
      notification when it's done, or wait here.
    </p>
  """

  @downloadCompleteTemplate: """
    <div id="close-modal">X</div>
    <h2>Download available</h2>

    <p>
      Your personalised dataset has been generated and is ready for download.
    </p>

    <p class="link-container">
    </p>
  """

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
