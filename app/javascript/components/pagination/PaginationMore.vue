<template>
  <button
    v-html="text"
    @click="submit"
  />
</template>

<script>
export default {
  name: 'pagination-more',

  props: {
    text: {
      type: String,
      required: true
    }
  }, 

  data () {
    return {
      currentPage: 1
    }
  },

  methods: {
    submit () {

      console.log('submit view more')

      this.$emit('request-more', this.currentPage + 1)
    }
  }
} 
</script>