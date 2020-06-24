<template>
  <div id="sticky" :class="{ 'table-head--stuck' : isSticky }">
    <div class="table-head__row">
      <table-header v-for="filter, index in filters" :filter="filter" :key="index"></table-header>
    </div>
  </div>
</template>

<script>
  import TableHeader from './TableHeader.vue'

  export default {
    name: 'pame-table-head',

    components: { TableHeader },

    props: {
      filters: {
        required: true,
        type: Array
      }
    },

    data() {
      return {
        stickyTrigger: 0,
        isSticky: false
      }
    },

    mounted () {
      this.setStickyTrigger()
      this.scrollHandler()
    },

    methods: {
      setStickyTrigger () {
        const stickyElement = document.getElementById('sticky')
        const stickyElementHeight = stickyElement.clientHeight
        const stickyYOffset = stickyElement.getBoundingClientRect().top + window.pageYOffset

        this.stickyTrigger = stickyElementHeight + stickyYOffset
      },

      scrollHandler () {
        setInterval( () => {
          let scrollY = window.pageYOffset

          this.isSticky = scrollY > this.stickyTrigger ? true : false
        }, 100)
      }
    }
  }
</script>
