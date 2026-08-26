<template>
  <li class="ct-map-overlay">
    <!-- One control per row, not two: the row used to be a clickable `<li>` with
         its own role/tabindex wrapping a separately focusable toggler, so the same
         state was announced twice and keyboard users hit it twice. The whole row is
         now the switch; the toggler inside it draws the ON/OFF pill only. -->
    <button
      v-if="isToggleable"
      class="ct-map-overlay__control ct-map-overlay__control--toggleable"
      type="button"
      role="switch"
      :aria-checked="isShown"
      @click.stop="onClick"
    >
      <span
        class="ct-map-overlay__color"
        :style="{ backgroundColor: color }"
      />
      <span
        class="ct-map-overlay__description"
        v-text="title"
      />
      <span class="ct-map-overlay__active-toggler">
        <MapToggler
          :active="isShown"
          presentational
        />
      </span>
    </button>
    <span
      v-else
      class="ct-map-overlay__control"
    >
      <span
        class="ct-map-overlay__color"
        :style="{ backgroundColor: color }"
      />
      <span
        class="ct-map-overlay__description"
        v-text="title"
      />
    </span>
  </li>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import MapToggler from '@/components/Map/Toggler.vue'
import useAnalytics from '@/composables/useAnalytics'
import { useMapOverlays, type MapOverlay } from '@/composables/useMapOverlays'
import type { MapFilterProps } from '@/types/backend'

type MapFilter = MapFilterProps
const props = withDefaults(defineProps<MapFilter>(), {
  color: '#cccccc',
  isShownByDefault: true,
  isToggleable: true
})

const { trackEvent } = useAnalytics()
const { visibleOverlays, addOverlay, removeOverlay } = useMapOverlays()

const overlay = computed<MapOverlay>(() => ({ layers: props.layers, id: props.id }))

const isShown = computed(() => visibleOverlays.value.some(o => o.id === props.id))

function setShown(shown: boolean) {
  if (shown) {
    addOverlay(overlay.value)
  }
  else {
    removeOverlay(overlay.value)
  }
}

function onClick() {
  if (!props.isToggleable) return

  const shown = !isShown.value
  setShown(shown)

  // Moved up from Map/Toggler.vue, which used to own the click. Same event name
  // and label so the GA4 history stays continuous.
  trackEvent('click', { event_label: `${props.id} - Toggle map layer: ${shown}` })
}

onMounted(() => {
  setShown(props.isShownByDefault)
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-map-overlay__control {
  @apply
  tw-shared-base-flex-gap-3
  items-center
  w-full
  text-left;
}

.ct-map-overlay__control--toggleable {
  @apply cursor-pointer;
}

.ct-map-overlay__color {
  @apply
  size-4.75
  rounded-full
  border
  border-white
  bg-theme-grey
  shrink-0;
}

.ct-map-overlay__description {
  @apply tw-shared-font-hind-siliguri__light-sm-lg-base-white;
}

</style>
