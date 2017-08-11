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
      'interactive-multiline': VComponents['vue/charts/InteractiveMultiline'],
      'sunburst': VComponents['vue/charts/Sunburst'],
      'treemap': VComponents['vue/charts/Treemap'],
      'counter': VComponents['vue/components/Counter'],
      'horizontal-bar': VComponents['vue/components/horizontal_bars/HorizontalBar'],
      'horizontal-bars': VComponents['vue/components/horizontal_bars/HorizontalBars'],
      'interactive-treemap': VComponents['vue/components/InteractiveTreemap']
    }
  })
)