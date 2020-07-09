<template>
  <div 
    :class="['modal--download', { 'active' : isActive }]"
  >
    <div class="modal__topbar">
      <span>Downloads</span>
      <span
        @click="toggle"
      >-</span>
    </div>
    <div 
      :class="['modal__content', { 'minimised': isMinimised }]"
    >
      <span class="modal__title">Citation</span>
      <p>UNEP-WCMC (2019). Protected Area Profile for France from the World Database of Protected Areas, December 2019. Available at: www.protectedplanet.net</p>

      <ul class="modal__ul">
        <li class="modal__li">
          <span modal__li-title>Filename</span>
          <span modal__li-icon>O</span>
          <a href="/" class="modal__a button--download-small" />
          <span modal__li-delete>x</span>
        </li>
      </ul>
    </div>
  </div>
</template>
<script>
export default {
  name: 'download-modal',

  props: {
    // options: Array, //[ { title: String, commercialAvailable: Boolean, params: Object } ]
    isActive: {
      default: false,
      type: Boolean
    }
  },

  data () {
    return {
      isMinimised: false
    }
  },

  methods: {
    toggle () {
      this.isMinimised = !this.isMinimised
    }
  }
}
</script>