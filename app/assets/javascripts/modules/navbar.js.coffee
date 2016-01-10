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

      @resourcesDropdown = new Dropdown(
        $('.js-resources-dd-trigger'),
        $('.js-resources-dd-target')
      )


  return Navbar
)

