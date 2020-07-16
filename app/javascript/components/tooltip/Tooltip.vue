<template>
  <div 
    :class="['tooltip', { 'tooltip--active': isActive }]"
  >
    <div 
      v-if="onHover"
      v-touch="toggleTooltip"
      tabindex="0"
      :aria-describedby="id"
      :aria-expanded="isActive"
      class="tooltip__trigger"
      @mouseenter="toggleTooltip(true)"
      @mouseleave="toggleTooltip(false)"
    >
      <slot />
    </div>
    <div 
      v-else
      tabindex="0"
      :aria-describedby="id"
      :aria-expanded="isActive"
      class="tooltip__trigger"
      @click="toggleTooltip"
    >
      <slot />
    </div>
      
    <div
      v-show="isActive"
      :id="id"
      role="tooltip"
      class="tooltip__target"
    >
      <button 
        v-if="!onHover" 
        @click="toggleTooltip(false)" 
        class="tooltip__close"
      />

      <div v-html="text" />
    </div>
  </div>
</template>

<script>
import mixinPopupCloseListeners from '../../mixins/mixin-popup-close-listeners'

export default {
  name: 'tooltip',

  mixins: [ mixinPopupCloseListeners({ closeCallback: 'closeTooltip' }) ],

  props: {
    text: {
      type: String,
      required: true
    },
    onHover: {
      type: Boolean,
      default: true
    }
  },

  data () {
    return {
      id: `tooltip_${this._uid}`,
      isActive: false
    }
  },

  mounted () {   
    if(this.onHover) {
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
    toggleTooltip (boolean) {
      console.log('click', this.id)
      console.log('click', boolean)
      this.isActive = typeof boolean == 'boolean' ? boolean : !this.isActive
    },

    closeTooltip () {
      this.toggleTooltip(false)
    }
  }
}  
</script>