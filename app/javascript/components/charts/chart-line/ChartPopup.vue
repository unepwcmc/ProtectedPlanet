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
    
    <!-- <polyline 
      v-show="showPopup"
      :points="xAxisLine" 
      fill="none" 
      stroke="black" 
    /> -->
    <g
      v-show="showPopup"
      :transform="`translate(${coordX}, ${coordY})`"
    >
      <path 
        d="m-1.5,-8.54687c-3,-22 -50,-14 -50.5,-14.45313c0.5,0.45313 -0.5,-58.54687 -0.5,-58.54687c0,0 104,1 104,1c0,0 1,57 0.5,56.54687c0.5,0.45313 -43.5,2.45313 -44,2c0.5,0.45313 -6.5,35.45313 -9.5,13.45313z" 
        stroke-width="1.5" 
        stroke="#000" 
        fill="#000"
      />
      <text
        font-size="26"
        font-weight="500"
        fill="#fff"
        text-anchor="middle"
        dy="-30"
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
    // showPopup: {
    //   type: Boolean
    // },
    colour: {
      required: true,
      type: String
    },
    text: {
      required: true,
      type: Number
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