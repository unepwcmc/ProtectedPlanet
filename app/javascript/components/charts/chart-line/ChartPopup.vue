<template>
  <g
    v-show="showPopup"
    :transform="`translate(${x}, ${coordY})`"
  >
    <rect 
      fill="#000"
      height="46"
      rx="4"
      :width="popupWidth"    
      :x="-popupWidth/2"
      y="-58"
    />
    <path 
      d="m-17,-13l17.132,12.2l16.04,-12.2l-33.172,0z" 
      fill="#000"
    />
    <text
      font-size="20"
      font-weight="700"
      fill="#fff"
      text-anchor="middle"
      dy="-27"
    >
      {{ text }}
    </text>
  </g>
</template>

<script>
export default {
  name: 'chart-popup',

  props: {
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
    coordY () {
      return this.y - 10
    },
    popupWidth () {
      return (this.text.replace('.', '').length * 12) + 20
    }
  },

  methods: {
    togglePopup () {
      this.showPopup = !this.showPopup
    }
  }
}
</script>