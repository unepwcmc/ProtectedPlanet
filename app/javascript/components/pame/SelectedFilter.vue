<template>
  <div class="selected__option">
    
    <p class="selected__text">{{ option }}</p>

    <button @click="deselectOption()" class="selected__close fa fa-times"></button>
  </div>
</template>

<script>
  import { eventHub } from '../../vue.js'

  export default {
    name: 'selected-filter',

    props: {
      name: {
        required: true,
        type: String
      },
      option: {
        required: true,
        type: String
      }
    },

    methods: {
      deselectOption () {
        // remove this option from the active filter list and update results
        this.$store.commit('pame/removeFilterOption', { name: this.name, option: this.option })
        this.$eventHub.$emit('deselectOption', { name: this.name, option: this.option })
        this.$eventHub.$emit('filtersChanged')
      }
    }
  }
</script>
