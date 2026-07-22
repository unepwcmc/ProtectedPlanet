<template>
  <a
    :id="link.id"
    role="menuitem"
    :class="['nav__a', { 'is-current-page': link.is_current_page }]"
    :href="link.url"
  >
    {{ link.label }}
  </a>
</template>

<script setup lang="ts">
import type { NavLink } from '@/types/backend'

defineProps<{ link: NavLink }>()
</script>
