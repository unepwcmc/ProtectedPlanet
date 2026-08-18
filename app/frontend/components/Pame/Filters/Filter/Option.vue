<template>
  <li class="ct-pame-filter-option">
    <input
      :id="optionId"
      type="checkbox"
      class="ct-pame-filter-option__checkbox"
      :checked
      @change="onChange"
    >
    <label
      :for="optionId"
      class="ct-pame-filter-option__checkbox-label"
    >
      <span class="ct-pame-filter-option__checkbox-square">
        <IconTick
          v-if="checked"
          class="ct-pame-filter-option__checkbox-icon"
        />
      </span>
      <span
        class="ct-pame-filter-option__checkbox-text"
        v-text="option"
      />
    </label>
  </li>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import IconTick from '@/components/Icon/Tick.vue'

const props = defineProps<{
  option: string
  checked: boolean
  groupId: string
}>()

const emit = defineEmits<{ click: [checked: boolean] }>()

const optionId = computed(() => `${props.groupId}-${props.option.replace(/[\s()_]/g, '-').toLowerCase()}`)

const onChange = (event: Event) => emit('click', (event.target as HTMLInputElement).checked)
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-pame-filter-option {
  @apply
  grow
  w-full
  tw-shared-base-flex-gap-1
  items-center
  p-2
  cursor-pointer;
}

.ct-pame-filter-option__checkbox {
  @apply hidden;
}

.ct-pame-filter-option__checkbox-label {
  @apply
  tw-shared-base-flex-gap-2
  items-center;
}

.ct-pame-filter-option__checkbox-square {
  @apply
  shrink-0
  size-6
  border
  border-theme-grey
  flex
  items-center;
}

.ct-pame-filter-option__checkbox-icon {
  @apply
  size-4
  grow
  text-theme-primary;
}

.ct-pame-filter-option__checkbox-text {
  @apply tw-shared-font-hind-siliguri__light-base-grey-black;
}
</style>
