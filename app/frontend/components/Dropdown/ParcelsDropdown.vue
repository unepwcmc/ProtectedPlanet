<template>
  <div
    v-if="showDropdown"
    class="ct-dropdown-parcels-dropdown"
  >
    <div class="ct-dropdown-parcels-dropdown__top">
      <h2
        class="ct-dropdown-parcels-dropdown__title"
        v-text="title"
      />
      <span
        v-if="showDescription"
        class="ct-dropdown-parcels-dropdown__description"
        v-text="description"
      />
    </div>
    <DropdownBase
      v-model="chosenParcelId"
      class="ct-dropdown-parcels-dropdown__dropdown"
      :title="dropdownTitle"
      :options="sitePids"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import DropdownBase from '@/components/Dropdown/Base.vue'
import useParcelSelection from '@/composables/useParcelSelection'
import type { AttributesParcelsDropdownProps } from '@/types/backend'

type AttributesParcelsDropdown = AttributesParcelsDropdownProps
const props = defineProps<AttributesParcelsDropdown>()

const { selectedParcelId, selectParcel } = useParcelSelection()

const chosenParcelId = ref<string | undefined>(undefined)

const moreThanOneParcels = props.sitePids.length > 1
const showDropdown = computed(() => moreThanOneParcels && !props.forPdf)
const showDescription = moreThanOneParcels && !!props.description

watch(chosenParcelId, (newParcelId) => {
  if (newParcelId) selectParcel(newParcelId)
})

onMounted(() => {
  if (props.sitePids.length === 0 || props.forPdf) return

  const pidFromUrl = selectedParcelId.value
  chosenParcelId.value = (pidFromUrl && props.sitePids.includes(pidFromUrl))
    ? pidFromUrl
    : props.sitePids[0]
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-dropdown-parcels-dropdown {
  @apply tw-shared-card-stats;
}

.ct-dropdown-parcels-dropdown__top {
  @apply tw-shared-base-flex-col-gap-3;
}

.ct-dropdown-parcels-dropdown__title {
  @apply tw-shared-list-title;
}

.ct-dropdown-parcels-dropdown__description {
  @apply tw-shared-list-underline-value;
}

.ct-dropdown-parcels-dropdown__dropdown {
  @apply lg:max-w-100;
}
</style>
