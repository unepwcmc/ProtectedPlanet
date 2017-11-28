<template>
  <div class="sticky-tab" @click="toggleTab" :class="{ 'sticky-tab--open' : isActive }">
    <div class="sticky-tab__text">
      <slot></slot>
    </div>
    <i class="sticky-tab__icon fa fa-share-alt"></i>
  </div>
</template>

<script>
  module.exports = {
    name: 'sticky-tab',

    data: function () {
      return  {
        isActive: false
      }
    },

    methods: {
      toggleTab: function () {
        if (!this.isActive) {
          const self = this

          window.setTimeout(function () {
            self.isActive = false
          }, 5000)
        }

        this.isActive = !this.isActive
      }
    }
  }
</script>