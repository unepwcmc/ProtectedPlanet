<template>
  <ul
    aria-label="nav"
    role="menubar"
    class="ct-nav-bar-desktop__list"
  >
    <li
      v-for="link in links"
      :key="link.id"
      role="none"
      class="ct-nav-bar-desktop__item"
    >
      <NavBarDropdownDesktop
        v-if="hasChildren(link)"
        :link
      />
      <NavBarLink
        v-else
        :link
      />
    </li>
  </ul>
</template>

<script setup lang="ts">
import type { NavLink as NavLinkType } from '@/types/backend'
import NavBarDropdownDesktop from '@/components/NavBar/Dropdown/Desktop.vue'
import NavBarLink from '@/components/NavBar/Link.vue'

defineProps<{ links: NavLinkType[] }>()

function hasChildren(link: NavLinkType): boolean {
  return Boolean(link.children)
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-nav-bar-desktop__list {
  @apply
  tw-shared-base-flex-gap-3
  items-center
  h-full;
}

.ct-nav-bar-desktop__item {
  @apply h-full flex items-center;
}
</style>
