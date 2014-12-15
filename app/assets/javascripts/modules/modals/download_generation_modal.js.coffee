define('download_generation_modal', ['modal'], (Modal) ->
  class DownloadGenerationModal extends Modal
    BASE_DOWNLOAD_PATH = '/downloads'

    @template: -> $('#download-modal-template').html()
    @downloadCompleteTemplate: -> $('#download-complete-modal-template').html()

    constructor: ($container) ->
      super($container)

    initialiseForm: (token) ->
      $form = @$container.find('form')
      return if $form.length is 0

      $form.attr('action', "/downloads/#{token}")
      $form.on("ajax:success", => @hide())


    showDownloadCompleteTemplate: ->
      @render(@constructor.downloadCompleteTemplate)
      @show()

    showDownloadLink: (filename, token) ->
      @showDownloadCompleteTemplate()

      download_url = @url(filename, token)
      @find('.link-container').html("""
        <a target="_blank" class="btn btn-primary" href="#{download_url}">Download</a>
      """)

    url: (filename, type) ->
      "#{BASE_DOWNLOAD_PATH}/#{filename}?type=#{type}"

  return DownloadGenerationModal
)
