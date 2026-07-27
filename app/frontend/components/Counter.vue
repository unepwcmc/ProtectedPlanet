<template>
  <span
    v-if="total >= 0"
    v-text="styledNumber"
  />
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import type { CounterProps } from '@/types/backend'

type Counter = CounterProps
const props = withDefaults(defineProps<Counter>(), {
  config: () => ({ speed: 30, divisor: 50 }),
  decimal: 2,
  animate: false
})

const number = ref(0)
const step = ref(0)
const increase = ref(true)

function calculateStep() {
  step.value = Math.abs(props.total - number.value) / props.config.divisor
}

function checkDirection() {
  increase.value = number.value < props.total
}

function count() {
  checkDirection()

  const interval = window.setInterval(() => {
    if (increase.value && number.value + step.value < props.total) {
      number.value += step.value
    }
    else if (!increase.value && number.value - step.value > props.total) {
      number.value -= step.value
    }
    else {
      number.value = props.total
      clearInterval(interval)
    }
  }, props.config.speed)
}

const styledNumber = computed(() => {
  const roundingNumber = Math.pow(10, props.decimal)
  return (Math.round(number.value * roundingNumber) / roundingNumber).toLocaleString()
})

watch(() => props.total, () => {
  calculateStep()
  count()
})

calculateStep()

onMounted(() => {
  if (props.animate) count()

  // Replaces the Vue 2 version's `scrollmagic` dependency — native IntersectionObserver
  // gives the same "fire once when the trigger element enters view" behaviour.
  const triggerEl = document.querySelector(`.${props.trigger}`)
  if (!triggerEl) return

  const observer = new IntersectionObserver((entries) => {
    if (entries.some(entry => entry.isIntersecting)) {
      count()
      observer.disconnect()
    }
  })
  observer.observe(triggerEl)
})
</script>
