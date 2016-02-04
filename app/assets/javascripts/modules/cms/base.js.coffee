$(document).ready( ->
  require(['cms:article_navigation', 'expandable_section'], (ArticleNavigation, ExpandableSection) ->
    if $verticalNav = $('.vertical-nav')
      ArticleNavigation.initialize($verticalNav)
  )
)
