<template>
  <a 
    :href="href" 
    @click="click"
  >
    <slot />
  </a>
</template>

<script>
export default {
  props: {
    gaId: {
      type: String,
      default: ''
    },

    href: {
      type: String,
      required: true
    }
  },

  methods: {
    click () {
      if(this.gaId) {
        const eventLabel = `Link - ${this.gaId}`

        this.$ga.event('Button', 'click', eventLabel)
      }
    }
  }
}
</script>