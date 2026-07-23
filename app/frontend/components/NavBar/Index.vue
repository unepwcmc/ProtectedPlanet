<template>
  <div
    ref="rootEl"
    class="nav"
  >
    <div
      :id="paneId"
      class="nav__pane"
      :class="{ 'nav-pane--active': isNavPaneActive }"
    >
      <button
        v-show="isBurgerNav"
        id="close-nav-pane"
        class="nav__close"
        @click="closePanel"
      />
      <ul
        aria-label="nav"
        role="menubar"
        class="nav__ul"
      >
        <li
          v-for="link in links"
          :key="link.id"
          role="none"
          class="nav__li"
        >
          <NavBarDropdown
            v-if="hasChildren(link)"
            :link="link"
          />
          <NavBarLink
            v-else
            :link="link"
          />
        </li>
      </ul>
    </div>
    <button
      v-show="isBurgerNav"
      :id="triggerId"
      class="nav__burger"
      @click="openPanel"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import type { NavLink as NavLinkType } from '@/types/backend'
import NavBarDropdown from '@/components/NavBar/Dropdown.vue'
import NavBarLink from '@/components/NavBar/Link.vue'
import { usePopupCloseListeners } from '@/composables/usePopupCloseListeners'
import { useBreakpoint } from '@/composables/useBreakpoint'

const props = withDefaults(defineProps<{ links: NavLinkType[], isAlwaysBurger?: boolean }>(), {
  isAlwaysBurger: false
})

const paneId = 'nav-pane'
const triggerId = 'open-nav-pane'

const isNavPaneActiveData = ref(false)
const rootEl = ref<HTMLElement | null>(null)

const { isSmall } = useBreakpoint()

const isBurgerNav = computed(() => props.isAlwaysBurger || isSmall.value)
const isNavPaneActive = computed(() => isNavPaneActiveData.value && isBurgerNav.value)

function openPanel() {
  isNavPaneActiveData.value = true
}

function closePanel() {
  isNavPaneActiveData.value = false
}

usePopupCloseListeners(rootEl, {
  isActive: isNavPaneActive,
  onClose: closePanel
})

function hasChildren(link: NavLinkType): boolean {
  return Boolean(link.children)
}
</script>
