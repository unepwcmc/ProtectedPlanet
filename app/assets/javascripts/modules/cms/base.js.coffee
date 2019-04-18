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

  if $iframe = $('iframe')
    $iframe.width('100%')
    $iframe.height 281/500 * $iframe.width()

    window.addEventListener 'resize', ->
      $iframe.height 281/500 * $iframe.width()

  # generate a new vue instance and initialise all the vue components on the page
  new Vue({
    el: '.v-cms-content',
    components: {
      'select-with-content': VComponents['vue/components/SelectWithContent'],
      'wdpa-download-tool': VComponents['vue/components/wdpa_download_tool/WdpaDownloadTool']
    }
  })
)
