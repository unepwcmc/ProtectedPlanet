<template>
  <span 
    :class="smTriggerElement"
    v-show="showTrigger"
  />
</template>

<script>
import ScrollMagic from 'scrollmagic'

export default {
  name: 'pagination-infinity-scroll',

  props: {
    smTriggerElement: {
      type: String,
      required: true
    },
    total: {
      default: 0,
      type: Number
    },
    totalPages: {
      default: 0,
      type: Number
    }
  }, 

  data () {
    return {
      currentPage: 1,
      scrollMagicHandlersActive: false
    }
  },

  mounted () {
    this.scrollMagicHandlerInit()

    if(this.showTrigger) { this.scrollMagicHandlerAdd() }

    this.$eventHub.$on('reset:pagination', this.reset)
  },

  computed: {
    showTrigger () {
      return this.currentPage < this.totalPages
    }
  },

  methods: {
    requestMore () {
      this.currentPage = this.currentPage + 1
      
      this.$emit('request-more', this.currentPage)
      
      if(!this.scrollMagicHandlersActive) { 
        this.scrollMagicHandlerAdd()
      }

      if(this.currentPage == this.totalPages) { 
        this.scrollMagicHandlerRemove()
      }
    },

    reset () {
      this.scrollMagicHandlerRemove()
      this.currentPage = 1
    },

    scrollMagicHandlerAdd () {
      this.scrollMagicController.addScene(this.scrollMagicScene)
      this.scrollMagicHandlersActive = true
    },

    scrollMagicHandlerInit () {
      console.log('init')
      this.scrollMagicController = new ScrollMagic.Controller()

      this.scrollMagicScene = new ScrollMagic.Scene({ triggerElement: `.${this.smTriggerElement}` })
        .triggerHook('onEnter')
        .on('enter', () => {
          this.requestMore()
        })
    },

    scrollMagicHandlerRemove () {
      this.scrollMagicController.removeScene(this.scrollMagicScene)
      this.scrollMagicHandlersActive = false
    }
  }
} 
</script>