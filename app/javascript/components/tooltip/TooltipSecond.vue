<template>
  <div :class="['tooltip', { 'tooltip--active': isActive }]">
    <button
      v-if="onHover"
      v-touch="toggleTooltip"
      tabindex="0"
      :aria-describedby="id"
      :aria-expanded="isActive"
      class="tooltip__trigger"
      @mouseenter="toggleTooltip(true)"
      @mouseleave="toggleTooltip(false)"
    >
      <slot name="trigger" />
    </button>
    <div
      v-else
      tabindex="0"
      :aria-describedby="id"
      :aria-expanded="isActive"
      class="tooltip__trigger"
      @click="toggleTooltip"
    >
      <slot name="trigger" />
    </div>

    <div
      v-show="isActive"
      :id="id"
      role="tooltip"
      class="tooltip__target-second"
    >
      <div class="tooltip__header">
        <slot name="header" />
        <button
          v-if="!onHover"
          class="tooltip__target-second--close"
          @click="toggleTooltip(false)"
        />
      </div>
      <slot name="content" />
    </div>
  </div>
</template>

<script>
import mixinPopupCloseListeners from '../../mixins/mixin-popup-close-listeners'

export default {
  name: 'Tooltip',

  mixins: [mixinPopupCloseListeners({ closeCallback: 'closeTooltip' })],

  props: {
    onHover: {
      type: Boolean,
      default: true
    }
  },

  data() {
    return {
      id: `tooltip_${this._uid}`,
      isActive: true
    }
  },

  mounted() {
    if (this.onHover) {
      const tooltipTrigger = this.$el.querySelector('.tooltip__trigger')

      tooltipTrigger.addEventListener('blur', () => {
        this.toggleTooltip(false)
      })
      tooltipTrigger.addEventListener('focus', () => {
        this.toggleTooltip(true)
      })
    }
  },

  methods: {
    toggleTooltip(boolean) {
      this.isActive = typeof boolean == 'boolean' ? boolean : !this.isActive
    },

    closeTooltip() {
      this.toggleTooltip(false)
    }
  }
}  
</script>