<template>
  <button
    v-show="hasMoreResults"
    v-html="buttonText"
    class="button--all"
    @click="click()"
  />
</template>

<script>
import ScrollMagic from 'scrollmagic'

export default {
  name: 'pagination-more',

  props: {
    smTriggerElement: {
      type: String,
      required: true
    },
    text: {
      type: String,
      required: true
    },
    total: {
      type: Number,
      required: true
    },
    totalPages: {
      type: Number,
      required: true
    }
  }, 

  data () {
    return {
      currentPage: 0,
      getMoreBoolean: true,
      scrollMagicHandlersActive: false
    }
  },

  mounted () {
    this.scrollMagicHandlerInit()
    this.$eventHub.$on('reset-pagination', this.reset)
  },

  computed: {
    buttonText () {
      return this.getMoreBoolean ? this.text : 'View less'
    },

    hasMoreResults () {
      return this.total > 0
    }
  },

  methods: {
    click () {
      this.getMoreBoolean == true ? this.requestMore() : this.reset()
    },

    requestMore () {
      this.currentPage = this.currentPage + 1
      
      this.$emit('request-more', this.currentPage)
      
      if(!this.scrollMagicHandlersActive) { 
        this.scrollMagicHandlerAdd()
      }

      if(this.currentPage == this.totalPages) { 
        this.scrollMagicHandlerRemove()
        this.getMoreBoolean = false 
      }
    },

    reset () {
      this.scrollMagicHandlerRemove()
      this.currentPage = 0
      this.getMoreBoolean = true
      this.$emit('reset-pagination')
    },

    scrollMagicHandlerAdd () {
      this.scrollMagicController.addScene(this.scrollMagicScene)
      this.scrollMagicHandlersActive = true
    },

    scrollMagicHandlerInit () {
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