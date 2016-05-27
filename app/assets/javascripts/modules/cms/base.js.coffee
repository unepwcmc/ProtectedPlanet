$(document).ready( ->
  require(['cms:article_navigation', 'cms:external_links'], (ArticleNavigation, ExternalLinks) ->
    if $verticalNav = $('.vertical-nav')
      ArticleNavigation.initialize($verticalNav)

    if $links = $('.article a')
      ExternalLinks.initialize($links)
  )
)
