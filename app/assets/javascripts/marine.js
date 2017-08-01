//= require vue
//= require d3
//= require charts/Sunburst

console.log('marine')

new Vue({
  el: '#sunburst',
  components: {
    'sunburst': VComponents['charts/Sunburst']
  }
})