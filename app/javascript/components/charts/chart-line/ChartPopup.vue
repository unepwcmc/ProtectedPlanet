<template>
  <g>
    <circle
      :fill="colour"
      :cx="x" 
      :cy="y"
      r="8"
      @mouseover="togglePopup()"
      @mouseleave="togglePopup()"
    />
    
    <g
      v-show="showPopup"
      :transform="`translate(${coordX}, ${coordY})`"
    >
      <rect 
        fill="#000"
        height="46"
        rx="4"
        width="74"    
        x="-36"
        y="-58"
      />
      <path 
        d="m-17,-13l17.132,12.2l16.04,-12.2l-33.172,0z" 
        fill="#000"
      />
      <text
        font-size="26"
        font-weight="700"
        fill="#fff"
        text-anchor="middle"
        dy="-27"
      >
        {{ text }}
      </text>
    </g>
  </g>
</template>

<script>
export default {
  name: 'chart-popup',

  props: {
    colour: {
      required: true,
      type: String
    },
    text: {
      required: true,
      type: String
    },
    x: {
      required: true,
      type: Number
    },
    y: {
      required: true,
      type: Number
    }
  },

  data () {
    return {
      showPopup: false
    }
  },

  computed: {
    coordX () {
      return this.x
    },
    coordY () {
      return this.y - 10
    }
  },

  methods: {
    togglePopup () {
      this.showPopup = !this.showPopup
    }
  }
}
</script>