<template>
  <div 
    class="tooltip"
  >
    <div v-if="onHover"
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
      v-touch="toggleTooltip"
      tabindex="0"
      :aria-describedby="id"
      :aria-expanded="isActive"
      class="tooltip__trigger"
      @click:prevent="toggleTooltip()"
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

      {{ text }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'Tooltip',

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
      isActive: false,
      id: `tooltip_${this._uid}`
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
      this.isActive = typeof boolean == 'boolean' ? boolean : !this.isActive
    }
  }
}  
</script>