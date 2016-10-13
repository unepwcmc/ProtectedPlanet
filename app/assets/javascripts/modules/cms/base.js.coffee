$(document).ready( ->
  require(['cms:article_navigation', 'cms:external_links'], (ArticleNavigation, ExternalLinks) ->
    if $verticalNav = $('.vertical-nav')
      ArticleNavigation.initialize($verticalNav)

    if $links = $('.article a')
      ExternalLinks.initialize($links)

    $cover = $('.hero__cover')

    if $cover.length > 0
      setPosition = ->
        top = window.scrollY
        position = Math.max((100 - top*0.25), 0)
        $cover.css("background-position", "50% #{position}%")

      $(window).scroll(setPosition)
      setPosition()
  )
)
