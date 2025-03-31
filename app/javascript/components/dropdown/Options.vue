<template>
   <ul class="ct-dropdown-options__options">
      <li class="ct-dropdown-options__option" v-for="(option, index) in options" :key="`${index}ct-dropdown-options`"
        @click="chooseOption(option)">{{ option }}</li>
    </ul>
</template>
<script>
export default {
  name: 'dropdown-options',
  props: {
    options: {
      type: Array,
      default: () => []
    }
  },

  methods: {
    chooseOption (option) {
      this.$emit('click', option)
    }
  }
}
</script>