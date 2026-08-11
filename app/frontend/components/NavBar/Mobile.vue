<template>
  <div
    ref="rootEl"
    class="ct-nav-bar-mobile"
  >
    <div
      :id="paneId"
      class="ct-nav-bar-mobile__pane"
      :class="{ 'ct-nav-bar-mobile__pane--active': isNavPaneActive }"
    >
      <button
        id="close-nav-pane"
        class="ct-nav-bar-mobile__close"
        @click="closePanel"
      >
        <IconClose class="ct-nav-bar-mobile__close-icon" />
      </button>
      <ul
        aria-label="nav"
        role="menubar"
        class="ct-nav-bar-mobile__list"
      >
        <li
          v-for="link in links"
          :key="link.id"
          role="none"
          class="ct-nav-bar-mobile__item"
        >
          <NavBarDropdownMobile
            v-if="hasChildren(link)"
            :link
          />
          <NavBarLink
            v-else
            :link
          />
        </li>
      </ul>
    </div>
    <button
      :id="triggerId"
      class="ct-nav-bar-mobile__burger"
      @click="openPanel"
    >
      <IconBurger class="ct-nav-bar-mobile__burger-icon" />
    </button>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import type { NavLink as NavLinkType } from '@/types/backend'
import NavBarDropdownMobile from '@/components/NavBar/Dropdown/Mobile.vue'
import NavBarLink from '@/components/NavBar/Link.vue'
import IconBurger from '@/components/Icon/Burger.vue'
import IconClose from '@/components/Icon/Close.vue'
import usePopupCloseListeners from '@/composables/usePopupCloseListeners'
import useFreezeBackground from '@/composables/useFreezeBackground'

defineProps<{ links: NavLinkType[] }>()

const paneId = 'nav-pane'
const triggerId = 'open-nav-pane'
const isNavPaneActive = ref(false)
const rootEl = ref<HTMLElement | null>(null)

function openPanel() {
  isNavPaneActive.value = true
}

function closePanel() {
  isNavPaneActive.value = false
}

usePopupCloseListeners(rootEl, {
  isActive: isNavPaneActive,
  onClose: closePanel
})

useFreezeBackground(isNavPaneActive)

function hasChildren(link: NavLinkType): boolean {
  return Boolean(link.children)
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-nav-bar-mobile {
  @apply
  flex
  items-center;
}

.ct-nav-bar-mobile__pane {
  @apply
  fixed
  top-0
  right-0
  bottom-0
  w-full
  h-full
  translate-x-full
  bg-white
  p-5
  transition-transform
  duration-400
  ease-in-out
  tw-shared-base-flex-col-gap-3;
}

.ct-nav-bar-mobile__pane--active {
  @apply
  z-3
  translate-x-0;
}

.ct-nav-bar-mobile__close {
  @apply
  tw-shared-button-basic
  self-end;
}

.ct-nav-bar-mobile__close-icon {
  @apply size-5;
}

.ct-nav-bar-mobile__list {
  @apply
  tw-shared-base-flex-col-gap-3
  h-full
  overflow-y-auto;
}

.ct-nav-bar-mobile__item {
  @apply h-auto;
}

.ct-nav-bar-mobile__burger {
  @apply
  tw-shared-button-basic
  block
  self-center;
}

.ct-nav-bar-mobile__burger-icon {
  @apply
  h-3.75
  w-6;
}
</style>
