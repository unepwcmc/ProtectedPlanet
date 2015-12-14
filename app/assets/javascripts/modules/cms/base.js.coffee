$(document).ready( ->
  require(['cms:article_navigation'], (ArticleNavigation) ->
    if $verticalNav = $('.vertical-nav')
      ArticleNavigation.initialize($verticalNav)
  )
)
