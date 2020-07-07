<template>
  <div class="modal--download">
    <div class="modal__topbar">
      <span>Downloads</span>
      <span>-</span>
    </div>
    <div class="modal__content">
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
    // text: String
  },

  data () {
    return {
      isActive: false,
      isMinimised: false
    }
  },

  methods: {
    
  }
}
</script>