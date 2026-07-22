<template>
  <div
    ref="rootEl"
    class="nav__dropdown"
    :class="{ active: isActive }"
    @mouseenter="openDropdown"
    @mouseleave="closeDropdown"
  >
    <button
      :id="triggerId"
      aria-haspopup="true"
      :aria-expanded="isActive"
      :aria-controls="modalId"
      class="nav__dropdown-toggle hover--pointer flex-inline flex-v-center"
    >
      <label :for="modalId">
        <NavBarLink
          :link="link"
          :class="[{ active: isActive }, 'nav__dropdown-toggle-a']"
          @touchend="toggleDropdown"
        />
      </label>
      <span class="drop-arrow arrow-svg" />
    </button>
    <nav
      :id="modalId"
      class="nav__dropdown-wrapper"
      :class="{ active: isActive }"
    >
      <NavBarLink
        v-for="dropdownLink in link.children"
        :key="dropdownLink.id"
        class="nav__dropdown-a"
        :link="dropdownLink"
      />
    </nav>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import type { NavLink } from '@/types/backend'
import NavBarLink from '@/components/NavBar/Link.vue'
import { usePopupCloseListeners } from '@/composables/usePopupCloseListeners'

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

function toggleDropdown(e: Event) {
  e.preventDefault()
  if (isActive.value) {
    closeDropdown()
  }
  else {
    openDropdown()
  }
}

usePopupCloseListeners(rootEl, {
  isActive,
  onClose: closeDropdown
})
</script>
