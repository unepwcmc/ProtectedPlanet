<template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 100 100"
  >
    <g
      v-for="bar in BARS"
      :key="bar.angle"
      :transform="`rotate(${bar.angle} 50 50)`"
    >
      <rect
        x="47"
        y="24"
        rx="9.4"
        ry="4.8"
        width="6"
        height="12"
        fill="currentColor"
      >
        <animate
          attributeName="opacity"
          values="1;0"
          keyTimes="0;1"
          dur="1s"
          :begin="bar.begin"
          repeatCount="indefinite"
        />
      </rect>
    </g>
  </svg>
</template>

<script setup lang="ts">
const BARS = [
  { angle: 0, begin: '-0.9166666666666666s' },
  { angle: 30, begin: '-0.8333333333333334s' },
  { angle: 60, begin: '-0.75s' },
  { angle: 90, begin: '-0.6666666666666666s' },
  { angle: 120, begin: '-0.5833333333333334s' },
  { angle: 150, begin: '-0.5s' },
  { angle: 180, begin: '-0.4166666666666667s' },
  { angle: 210, begin: '-0.3333333333333333s' },
  { angle: 240, begin: '-0.25s' },
  { angle: 270, begin: '-0.16666666666666666s' },
  { angle: 300, begin: '-0.08333333333333333s' },
  { angle: 330, begin: '0s' }
]
</script>
