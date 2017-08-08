$(document).ready( ->
  require(['map'], (Map) ->
    mapMarine = new Map($('#map-marine'))
    mapMarine.render()
  )

  new Vue({
    el: '.v-marine',
    components: {
      'sunburst': VComponents['vue/charts/Sunburst'],
      'treemap': VComponents['vue/charts/Treemap'],
      'counter': VComponents['vue/components/Counter'],
      'interactive-treemap': VComponents['vue/components/InteractiveTreemap']
    }
  })
)