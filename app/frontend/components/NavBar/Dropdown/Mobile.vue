<template>
  <div
    ref="rootEl"
    class="ct-nav-bar-dropdown-mobile"
  >
    <button
      :id="triggerId"
      aria-haspopup="true"
      :aria-expanded="isActive"
      :aria-controls="modalId"
      class="ct-nav-bar-dropdown-mobile__toggle"
      @click="toggleDropdown"
    >
      <NavBarLink
        :link
        class="nav-bar-dropdown-toggle ct-nav-bar-dropdown-mobile__label"
      />
      <IconArrow
        class="ct-nav-bar-dropdown-mobile__icon"
        :class="{ 'ct-nav-bar-dropdown-mobile__icon--active': isActive }"
      />
    </button>
    <nav
      :id="modalId"
      class="ct-nav-bar-dropdown-mobile__wrapper"
      :class="{ 'ct-nav-bar-dropdown-mobile__wrapper--active': isActive }"
    >
      <NavBarLink
        v-for="dropdownLink in link.children"
        :key="dropdownLink.id"
        class="ct-nav-bar-dropdown-mobile__link"
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

function closeDropdown() {
  isActive.value = false
}

function toggleDropdown(e: Event) {
  e.preventDefault()
  isActive.value = !isActive.value
}

usePopupCloseListeners(rootEl, {
  isActive,
  onClose: closeDropdown
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-nav-bar-dropdown-mobile {
  @apply flex flex-col;
}

.ct-nav-bar-dropdown-mobile__toggle {
  @apply
  tw-shared-button-basic
  flex
  w-full
  items-center
  justify-between
  gap-1;
}

.ct-nav-bar-dropdown-mobile__label {
  @apply grow;
}

.ct-nav-bar-dropdown-mobile__icon {
  @apply
  h-2
  w-3.5
  shrink-0
  text-theme-grey-black
  transition-transform
  duration-200;
}

.ct-nav-bar-dropdown-mobile__icon--active {
  @apply rotate-180;
}

.ct-nav-bar-dropdown-mobile__wrapper {
  @apply
  hidden
  w-full;
}

.ct-nav-bar-dropdown-mobile__wrapper--active {
  @apply tw-shared-base-flex-col;
}

.ct-nav-bar-dropdown-mobile__link {
  @apply
  w-full
  py-2.25
  pr-6
  pl-12
  leading-[1.2]
  hover:bg-theme-grey-dark
  hover:text-white;
}
</style>
