<template>
  <TooltipSecond :onHover="false">
    <template #trigger>
      <IconExclamationCircle class="ct-stats-tooltip-info__trigger-icon" />
    </template>
    <template #content>
      <div class="ct-stats-tooltip-info__content">
        <span v-text="props.description" />
        <span class="ct-stats-tooltip-info__designations">
          <span v-text="props.designationsLabel" />
          <span>=</span>
          <span v-text="props.designationsCount" />
        </span>
      </div>
    </template>
  </TooltipSecond>
</template>

<script setup lang="ts">
import TooltipSecond from '@/components/Tooltip/Second.vue'
import IconExclamationCircle from '@/components/Icon/ExclamationCircle.vue'
import type { StatsTooltipInfoProps } from '@/types/backend'

type StatsTooltipInfo = StatsTooltipInfoProps
const props = defineProps<StatsTooltipInfo>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-stats-tooltip-info__trigger-icon {
  @apply
  size-5
  text-theme-primary;
}

.ct-stats-tooltip-info__trigger-icon:hover {
  @apply text-theme-primary/70;
}

.ct-stats-tooltip-info__content {
  @apply
  tw-shared-base-flex-col-gap-6
  tw-shared-font-hind-siliguri__light-base-grey-black
  w-64
  lg:w-[19.188rem];
}

.ct-stats-tooltip-info__designations {
  @apply tw-shared-base-flex-gap-1;
}
</style>
