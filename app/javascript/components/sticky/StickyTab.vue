<template>
  <div class="sticky-tab" @click="toggleTab" :class="{ 'sticky-tab--open' : isActive }">
    <div class="sticky-tab__text">
      <slot></slot>
    </div>
    <i class="sticky-tab__icon fa fa-share-alt"></i>
  </div>
</template>

<script>
  export default {
    name: 'sticky-tab',

    data () {
      return  {
        isActive: false
      }
    },

    methods: {
      toggleTab () {
        if (!this.isActive) {
          window.setTimeout(() => {
            this.isActive = false
          }, 5000)
        }

        this.isActive = !this.isActive
      }
    }
  }
</script>