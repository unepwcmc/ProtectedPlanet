<template>
  <flickity 
    :options="flickityOptions"
    ref="flickity"
  >
    <slot />
  </flickity>
</template>

<script>
  import mixinResponsive from '../../mixins/mixin-responsive.js'

  import Flickity from 'vue-flickity';

  export default {
    name: 'carousel-flickity',

    components: { Flickity },

    mixins: [ mixinResponsive ],

    props: {
      options: {
        type: Object // { small: { FlicktyOptions }, medium: { FlicktyOptions }, large: { FlicktyOptions }}
      }
    },

    data () {
      return {
        flickityOptions: {},
        small: {},
        medium: {},
        large: {}
      }
    },

    created () {
      // this.setupOptions()

      // if ( matchMedia('screen and (min-width: 768px)').matches ) {
      //   console.log('here', this.large)
      //   this.flickityOptions = this.large;
      // }
    },

    mounted () {
      this.$eventHub.$on('windowResized', this.checkOptions)
    },

    watch: {
      currentBreakpoint () {
        console.log('new breakpoint', this.getCurrentBreakpoint())
        // const breakpoint = this.getCurrentBreakpoint()
        // console.log(this[breakpoint])
        // this.flickityOptions = this[this.getCurrentBreakpoint()]
        

       
      }
    },

    methods: {
      setupOptions () {
        if('small' in this.options) { this.small = this.options.small }
        if('medium' in this.options) { this.medium = this.options.medium }
        if('large' in this.options) { this.large = this.options.large }
      }
    }
  }
</script>