<template>
  <TooltipSecond
    :onHover="false"
    class="carousel__tooltip"
  >
    <template #trigger>
      <IconExclamationCircle class="card__tooltip--icon" />
    </template>
    <template #header>
      <span />
    </template>
    <template #content>
      <div class="card__tooltip--content">
        <span v-text="props.description" />
        <span class="card__tooltip--designations">
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
