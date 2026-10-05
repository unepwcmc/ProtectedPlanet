<template>
  <NavBarMobile
    class="ct-nav-bar__mobile"
    :links
  />
  <NavBarDesktop
    class="ct-nav-bar__desktop"
    :links
  />
</template>

<script setup lang="ts">
import type { NavLink as NavLinkType } from '@/types/backend'
import NavBarDesktop from '@/components/NavBar/Desktop.vue'
import NavBarMobile from '@/components/NavBar/Mobile.vue'

defineProps<{ links: NavLinkType[] }>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-nav-bar__mobile {
  @apply flex lg:hidden;
}

.ct-nav-bar__desktop {
  @apply hidden lg:flex;
}
</style>
