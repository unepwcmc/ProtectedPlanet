class @DownloadGenerationModal extends Modal
  @template: """
    <div id="download-modal" class="modal">
      <i class="fa fa-circle-o-notch fa-3x"></i>

      <h2>Generating download…</h2>
      <hr>
      <section>
        <div><h3>Get an email when the download is ready</h3></div>
      </section>
    </div>
  """

  constructor: ($container) ->
    super($container)

  startPolling: (path) ->
    @pollingId = setInterval

  fetchGenerationStatus = (path) ->
    $.getJSON

