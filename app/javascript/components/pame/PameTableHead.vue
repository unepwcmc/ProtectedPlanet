<template>
  <thead 
    id="sticky" 
    class="table-head table-head--pame" 
    :class="{ 'table-head--stuck': isSticky }"
  >
    <tr class="table-head__row">
      <table-header 
        v-for="(filter, index) in filters" 
        :key="`${filter.name}-${index}`"
        :filter="filter" 
      />
    </tr>
  </thead>
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

  mounted() {
    this.setStickyTrigger()
    this.scrollHandler()
  },

  methods: {
    setStickyTrigger() {
      const stickyElement = document.getElementById('sticky')
      const stickyElementHeight = stickyElement.clientHeight
      const stickyYOffset = stickyElement.getBoundingClientRect().top + window.pageYOffset

      this.stickyTrigger = stickyElementHeight + stickyYOffset
    },

    scrollHandler() {
      setInterval(() => {
        let scrollY = window.pageYOffset

        this.isSticky = scrollY > this.stickyTrigger ? true : false
      }, 100)
    }
  }
}
</script>
