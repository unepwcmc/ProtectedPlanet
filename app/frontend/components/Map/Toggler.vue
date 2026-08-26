<template>
  <span
    v-if="presentational"
    class="ct-map-toggler"
    :class="{ 'ct-map-toggler--active': active }"
    aria-hidden="true"
  >
    <span
      class="ct-map-toggler__switch"
      v-text="actionText"
    />
  </span>
  <button
    v-else
    class="ct-map-toggler"
    :class="{ 'ct-map-toggler--active': active }"
    type="button"
    role="switch"
    :aria-checked="active"
    :aria-label="label"
    @click.stop="toggle()"
  >
    <span
      class="ct-map-toggler__switch"
      v-text="actionText"
    />
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(defineProps<{
  active: boolean
  // "ON"/"OFF" is the whole visible text, so on its own the control announces no
  // subject. Callers pass the layer name they are toggling.
  label?: string
  presentational?: boolean
  onText?: string
  offText?: string
}>(), {
  label: undefined,
  presentational: false,
  onText: 'ON',
  offText: 'OFF'
})

const emit = defineEmits<{ change: [active: boolean] }>()

const actionText = computed(() => (props.active ? props.onText : props.offText))

// GA4 tracking used to live here, keyed off a gaId prop. It moved to the caller
// (Map/Overlay.vue) along with the click, so there is exactly one owner of the
// event whichever way the layer is toggled.
function toggle(newState?: boolean) {
  emit('change', typeof newState === 'boolean' ? newState : !props.active)
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-map-toggler {
  @apply
  inline-flex
  items-center
  justify-start
  border
  border-theme-grey-xlight
  rounded-[0.875rem]
  cursor-pointer
  select-none
  p-0.5
  min-w-13.25
  h-6.75;
}

.ct-map-toggler__switch {
  @apply
  inline-flex
  items-center
  rounded-[0.875rem]
  bg-theme-grey
  text-theme-grey-xdark
  text-sm
  font-semibold
  ml-auto
  mr-0
  h-full
  pt-0.5
  px-1
  pb-0;
}

.ct-map-toggler--active {
  @apply justify-end;
}

.ct-map-toggler--active .ct-map-toggler__switch {
  @apply bg-theme-grey-xlight ml-0 mr-auto transition-all duration-100 ease-in-out;
}

/* No hover state, deliberately: the legacy Sass nested `&__switch`/`&__active`
   straight onto `:hover` with no combinator, compiling to the invalid
   `:hover__switch`/`:hover__active`, so the hover never worked in any browser. */
</style>
