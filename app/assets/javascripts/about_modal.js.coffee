class @AboutModal
  @overlayTemplate: "<div class=\"total-overlay\"></div>"

  @template: """
    <div id="about-modal" class="modal">
      <h2>About this prototype</h2>
      <section>
        <p>
          alpha.protectedplanet.net is an experimental prototype and first
          iteration of our project to redevelop Protected Planet.
        </p>

        <p>
          It is intended to help us better understand and meet your
          needs as users, as well as explore the best technical approach
          for the product.
        </p>

        <p>
          This alpha release is a prototype, and whilst we are serving
          the latest version of the WDPA, there may be inconsistencies
          and errors. If you find something, please let us know about
          it!
        </p>

        <p>
          Your feedback is vital to us, so please leave any comments and
          suggestions you have. They will help us to shape protected
          planet over the coming months.
        </p>
      </section>

      <a href="#" id="close-modal"><i class="fa fa-times fa-2x"></i></a>
    </div>
  """

  constructor: ($container) ->
    @$overlay = $(@constructor.overlayTemplate)
    @$el = $(@constructor.template)

    $container.append(@$overlay)
    $container.append(@$el)

    $closeModalBtn = @$el.find('#close-modal')
    for $el in [@$overlay, $closeModalBtn]
      $el.on('click', (ev) =>
        @hide()
        ev.preventDefault()
      )

  show: ->
    @$el.addClass('opened')
    @$overlay.addClass('visible')

  hide: ->
    @$el.removeClass('opened')
    @$overlay.removeClass('visible')
