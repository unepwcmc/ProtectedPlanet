<template>
  <li class="filter__option">
    <input type="checkbox" :id="optionId" v-model="isSelected" class="filter__checkbox" :class="{ 'filter__checkbox--active' : isSelected }">
    <label :for="optionId" class="filter__checkbox-label">{{ option }}</label>
  </li>
</template>

<script>
  export default {
    name: 'data-filter-option',

    props: {
      option: {
        required: true
      }
    },

    data () {
      return {
        isSelected: false
      }
    },

    computed : {
      optionId () {
        return this.option.replace(' |(|)|_', '-').toLowerCase()
      }
    },

    methods: {
      selectOption (option) {
        this.isSelected = true
      }
    }
  }
</script>
