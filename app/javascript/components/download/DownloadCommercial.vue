<template>
  <div 
    :class="['modal-wrapper--download-commerical', { 'active' : isActive }]"
  >
    <div 
      :class="['modal--download-commerical', { 'active' : isActive }]"
    >
      <span 
        class="modal__close"
        @click="closeModal"
      />

      <h4 class="modal__title">Download Options</h4>

      <div class="modal__links">
        <a 
          class="modal__link-commercial"
          href="https://ibat-alliance.org/"
          target="_blank"
        >
          <span class="modal__link-title">Commercial Use</span>
          <span>Commercial use of the WDPA will redirect you to the IBAT website.</span>
        </a>

        <span class="modal__divider" />

        <div
        class="modal__link-non-commercial"
          @click="click"
        >
          <span class="modal__link-title">Non Commercial Use</span>
          <span>Download WDPA straight from the site.</span>
        </div>
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
    },

    closeModal () {
      this.$emit('click:close-modal')
    }
  }
}
</script>