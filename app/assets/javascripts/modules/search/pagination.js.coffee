define('pagination', [], ->
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
      )

  return Pagination
)
