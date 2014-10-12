class @DownloadGenerationModal extends Modal
  @template: """
    <div id="download-modal" class="modal">
      <i class="fa fa-circle-o-notch fa-3x"></i>
      <h2>Generating download…</h2>
    </div>
  """

  constructor: ($container) ->
    super($container)
