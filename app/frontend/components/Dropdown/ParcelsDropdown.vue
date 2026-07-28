<template>
  <div
    v-if="showDropdown"
    class="card--feault-block"
  >
    <div class="card__top">
      <h2
        class="card__h2"
        v-text="title"
      />
      <span
        v-if="showDescription"
        v-text="description"
      />
    </div>
    <DropdownBase
      v-model="chosenParcelId"
      class="card--attributes-parcels-dropdown"
      :title="dropdownTitle"
      :options="sitePids"
    />
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'
import DropdownBase from '@/components/Dropdown/Base.vue'
import { useParcelSelection } from '@/composables/useParcelSelection'
import type { AttributesParcelsDropdownProps } from '@/types/backend'

type AttributesParcelsDropdown = AttributesParcelsDropdownProps
const props = defineProps<AttributesParcelsDropdown>()

const { selectedParcelId, selectParcel } = useParcelSelection()

const chosenParcelId = ref<string | undefined>(undefined)

const moreThanOneParcels = props.sitePids.length > 1
const showDropdown = moreThanOneParcels && !props.forPdf
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
