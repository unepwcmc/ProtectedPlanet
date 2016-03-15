define('navbar', ['dropdown'], (Dropdown) ->
  class Navbar
    @initialize: ->
      instance = new Navbar()
      instance.initialize()

    initialize: ->
      $('.js-dropdown').each (i, el)  -> new Dropdown($(el))

  return Navbar
)

