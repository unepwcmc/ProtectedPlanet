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
        <a 
          class="modal__link-commercial"
          href="https://ibat-alliance.org/"
          target="_blank"
        >
          <span class="modal__link-title">{{ text.commercialTitle }}</span>
          <span>{{ text.commercialText }}</span>
        </a>

        <span class="modal__divider" />

        <div
        class="modal__link-non-commercial"
          @click="click"
        >
          <span class="modal__link-title">{{ text.nonCommercialTitle }}</span>
          <span>{{ text.nonCommercialText }}</span>
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
      type: Object //{ commercialText: String, commercialTitle: String, nonCommercialText: String, nonCommercialTitle: String, title: String }
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