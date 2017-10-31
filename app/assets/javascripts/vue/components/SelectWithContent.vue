<template>
  <div class="select-with-content">
    <select v-model="selected">
      <option :value="null">Select...</option>
      <option v-for="option in options" :value="option">{{ option.title }}</option>
    </select>

    <div v-if="selected" class="select-with-content__content">
      <img v-if="selected.image" :src="selected.image" :alt="'Visual results for ' + selected.title">

      <div v-if="selected.text" v-html="selected.text" class="select-with-content__text"></div>

      <a v-if="selected.url" :href="selected.url" title="View the protected area" class="button--grey">View the protected area</a>
    </div>
  </div>
</template>

<script>
  module.exports = {
    name: 'select-with-content',

    props: {
      options: {
        type: Array
      }
    },

    data: function() {
      return {
        selected: null
      }
    }
  }
</script>