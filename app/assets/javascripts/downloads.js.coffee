class @DownloadModal
  DEFAULT_TYPES = ['csv', 'shp', 'kml']
  BASE_DOWNLOAD_PATH = '/downloads'

  @overlayTemplate: "<div class=\"total-overlay\"></div>"

  @template: """
    <div id="download-modal">
    <i class="fa fa-cloud-download fa-3x"></i>
      <h2>Select a file type to download</h2>
      <section>
        <div id="link-container"></div>
        <h2>or</h2>
        <a href="http://ec2-54-204-216-109.compute-1.amazonaws.com:6080/arcgis/rest/services/wdpa/wdpa/MapServer" class="btn btn-primary">use our ESRI web service <i class="fa fa-external-link"></i></a>
      </section>
      <div>
        <a href="#" id="close-modal"><i class="fa fa-times fa-2x"></i></a>
      </div>
    </div>
  """

  constructor: ->
    @$overlay = $(@constructor.overlayTemplate)
    @$el = $(@constructor.template)

    for el in [@$overlay, @$el.find('#close-modal')]
      el.on('click', (e) =>
        @hide()
        e.preventDefault()
      )

  buildLinksFor: (objectName, types) ->
    types ||= DEFAULT_TYPES
    linkContainer = @$el.find('#link-container')

    newLinks = types.map((type) ->
      typeLinkText = type.toUpperCase()
      typeLinkHref = "#{BASE_DOWNLOAD_PATH}/#{objectName}?type=#{type}"

      newLink = "<a class=\"btn btn-primary\" href=\"#{typeLinkHref}\">#{typeLinkText}</a>"
      newLink
    )

    linkContainer.html(newLinks)

  show: ->
    @$el.addClass('opened')
    @$overlay.addClass('visible')

  hide: ->
    @$el.removeClass('opened')
    @$overlay.removeClass('visible')
