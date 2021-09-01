<template>
  <div 
    :class="['modal-wrapper--download-commercial', { 'active' : isActive }]"
  >
    <div 
      :class="['modal--download-commercial', { 'active' : isActive }]"
    >
      <span 
        class="modal__close"
        @click="closeModal"
      />

      <h4 class="modal__title">{{ text.title }}</h4>

      <div class="modal__links">
        <div class="modal__link">
          <span class="modal__link-title">{{ text.commercialTitle }}</span>
          <span class="modal__link-text" v-html="text.commercialText" />
        </div>

        <span class="modal__divider" />

        <div class="modal__link">
          <span class="modal__link-title">{{ text.nonCommercialTitle }}</span>
          <span class="modal__link-text">{{ text.nonCommercialText }}</span>
          <button
            class="modal__link-button"
            @click="click"
          >
            {{ text.nonCommercialButton }}
          </button>
        </div>
      </div>
    </div>
</div>
</template>
<script>
export default {
  name: 'download-commercial',

  props: {
    isActive: {
      default: false,
      type: Boolean
    },
    text: {
      required: true,
      type: Object //{ commercialText: String, commercialTitle: String, nonCommercialText: String, nonCommercialTitle: String, nonCommercialButton: String, title: String }
    },
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