define('pagination', ['asyncImg'], (asyncImg) ->
  class Pagination
    constructor: (@container, @resultClass) ->
      @render()

    render: ->
      @container.infinitescroll(
        navSelector: '.pagination'
        nextSelector: '.pagination a[rel=next]'
        itemSelector: @resultClass
        loading:
          msgText: ''
      , (newResults) ->
        asyncImg()
        $('#infscr-loading').remove()
        $('.pagination').remove()
      )

  return Pagination
)
