<template>
  
</template>

<script>
  import ScrollMagic from 'scrollmagic'

  export default {
    name: "chart-bar-stacked",

    mounted () {
      this.scrollMagicHandlers()
    },

    methods: {
      scrollMagicHandlers () {
        const marineScrollMagic = new ScrollMagic.Controller()

        new ScrollMagic.Scene({ triggerElement: '.sm-infographic', reverse: false })
          .setClassToggle('.sm-infographic .infographic__bar--pa', 'infographic__bar--pa--animate')
          .addTo(marineScrollMagic)
      }
    }
  }
</script>
