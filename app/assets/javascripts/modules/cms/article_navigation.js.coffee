define('cms:article_navigation', [], ->
  class ArticleNavigation
    @initialize: ($verticalNavEl) ->
      new ArticleNavigation($verticalNavEl).initialize()

    constructor: (@$verticalNavEl) ->

    initialize: ->
      @$verticalNavEl.find('.vertical-nav__element').click( (ev) ->
        $el = $(@)
        $el.addClass('vertical-nav__element--selected')
        $el.siblings().removeClass('vertical-nav__element--selected')
      )
)

