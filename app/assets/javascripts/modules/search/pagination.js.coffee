window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Search ||= {}

class ProtectedPlanet.Search.Pagination

  constructor: (@containerClass, @resultClass) ->
    @render()

  render: ->
    $(@containerClass).infinitescroll(
      navSelector: '.pagination'
      nextSelector: '.pagination a[rel=next]'
      itemSelector: @resultClass
      loading:
        msgText: ''
    )
