<template>
  <div
    ref="rootEl"
    class="ct-nav-bar-dropdown-desktop"
    :class="{ 'ct-nav-bar-dropdown-desktop--active': isActive }"
    @mouseenter="openDropdown"
    @mouseleave="closeDropdown"
  >
    <button
      :id="triggerId"
      aria-haspopup="true"
      :aria-expanded="isActive"
      :aria-controls="modalId"
      class="ct-nav-bar-dropdown-desktop__toggle"
    >
      <NavBarLink
        :link
        class="ct-nav-bar-dropdown-desktop__label"
      />
      <IconArrow
        class="ct-nav-bar-dropdown-desktop__icon"
        :class="{ 'ct-nav-bar-dropdown-desktop__icon--active': isActive }"
      />
    </button>
    <nav
      :id="modalId"
      class="ct-nav-bar-dropdown-desktop__wrapper"
      :class="{ 'ct-nav-bar-dropdown-desktop__wrapper--active': isActive }"
    >
      <NavBarLink
        v-for="dropdownLink in link.children"
        :key="dropdownLink.id"
        class="ct-nav-bar-dropdown-desktop__link"
        :link="dropdownLink"
      />
    </nav>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import type { NavLink } from '@/types/backend'
import NavBarLink from '@/components/NavBar/Link.vue'
import IconArrow from '@/components/Icon/Arrow.vue'
import usePopupCloseListeners from '@/composables/usePopupCloseListeners'

const props = defineProps<{ link: NavLink }>()

const modalId = `nav-dropdown-${props.link.id}`
const triggerId = `nav-dropdown-toggle-${props.link.id}`

const isActive = ref(false)
const rootEl = ref<HTMLElement | null>(null)

function openDropdown() {
  isActive.value = true
}

function closeDropdown() {
  isActive.value = false
}

usePopupCloseListeners(rootEl, {
  isActive,
  onClose: closeDropdown
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-nav-bar-dropdown-desktop {
  @apply
  relative
  flex
  h-full
  justify-center;
}

.ct-nav-bar-dropdown-desktop--active {
  @apply z-3;
}

.ct-nav-bar-dropdown-desktop__toggle {
  @apply
  tw-shared-button-basic
  flex
  items-center
  justify-center
  gap-1;
}

.ct-nav-bar-dropdown-desktop__icon {
  @apply
  h-2
  w-3.5
  shrink-0
  text-theme-grey-black
  transition-transform
  duration-200;
}

.ct-nav-bar-dropdown-desktop__icon--active {
  @apply rotate-180;
}

.ct-nav-bar-dropdown-desktop__wrapper {
  @apply
  absolute
  top-full
  left-0
  z-10
  hidden
  w-max
  bg-white;
}

.ct-nav-bar-dropdown-desktop__wrapper--active {
  @apply block;
}

.ct-nav-bar-dropdown-desktop__link {
  @apply
  w-63.5
  px-2.5
  py-2.25
  leading-[1.2]
  hover:bg-theme-grey-dark
  hover:text-white;
}
</style>
