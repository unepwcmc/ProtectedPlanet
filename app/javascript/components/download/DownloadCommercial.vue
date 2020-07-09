<template>
  <div 
    :class="['modal--download-commerical', { 'active' : isActive }]"
  >
    <h4>Download Options</h4>
    <div>
      <a href="https://ibat-alliance.org/">
        <span>Commercial Use</span>
        <span>Commercial use of the WDPA will redirect you to the IBAT website.</span>
      </a>

      <div
       class="modal__link-green"
        @click="click"
      >
        <span>Non Commercial Use</span>
        <span>Download WDPA straight from the site.</span>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  name: 'download-commerical',

  props: {
    isActive: {
      default: false,
      type: Boolean
    }
  },

  methods: {
    click (option) {
      this.$emit('click:non-commercial')
    }
  }
}
</script>