define('navbar', ['dropdown'], (Dropdown) ->
  class Navbar
    @initialize: ->
      instance = new Navbar()
      instance.initialize()

    initialize: ->
      $('.js-navbar-actionable').click( (ev) ->
        $el = $(@)
        $el.toggleClass('navbar__element--dark')
      )

      @thematicAreasDropdown = new Dropdown(
        $('.js-thematic-areas-dd-trigger'),
        $('.js-thematic-areas-dd-target')
      )


  return Navbar
)

