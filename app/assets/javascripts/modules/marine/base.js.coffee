$(document).ready( ->

  #generate map at the top of the page
  require(['map'], (Map) ->
    mapMarine = new Map($('#map-marine'))
    mapMarine.render()
  )

  #generate a new vue instance and initialise all the vue components on the page
  new Vue({
    el: '.v-marine',
    components: {
      'horizontal-bar-chart': VComponents['vue/charts/HorizontalBarChart'],
      'interactive-multiline': VComponents['vue/charts/interactive_multiline/InteractiveMultiline'],
      'sunburst': VComponents['vue/charts/Sunburst'],
      'treemap': VComponents['vue/charts/Treemap'],
      'counter': VComponents['vue/components/Counter'],
      'horizontal-bars': VComponents['vue/components/horizontal_bars/HorizontalBars'],
      'interactive-treemap': VComponents['vue/components/InteractiveTreemap']
      'rectangles': VComponents['vue/components/rectangles/Rectangles']
    }
  })
)