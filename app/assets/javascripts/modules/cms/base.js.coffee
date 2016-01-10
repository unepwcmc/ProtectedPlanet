$(document).ready( ->
  require(['cms:article_navigation', 'cms:expandable_section'], (ArticleNavigation, ExpandableSection) ->
    if $verticalNav = $('.vertical-nav')
      ArticleNavigation.initialize($verticalNav)
    if $expandableSections = $('.expandable-section')
      ExpandableSection.initialize($expandableSections)
  )
)
