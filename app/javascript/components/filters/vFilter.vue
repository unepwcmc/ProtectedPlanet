<template>
  <div class="filter">
    <div class="filter__header">
      <h4 v-if="title" v-html="title" class="filter__title" />
      <button class="filter__button-clear" @click="clearFilterOptions" v-html="textClear" />
    </div>
    <div class="filter__options">
      <checkboxes v-if="type == 'checkbox'" :clear-index="clearIndex" :id="id" :gaId="updatedGaId" :options="options"
        :pre-selected="preSelected" v-on:update:options="updateFilter" />
      <radio-buttons v-if="type == 'radio'" :clear-index="clearIndex" :id="id" :gaId="updatedGaId" :name="name"
        :options="options" v-on:update:options="updateFilter" />
    </div>
    <checkbox-search v-if="type == 'checkbox-search'" :clear-index="clearIndex" :gaId="updatedGaId" :id="id"
      :name="name" :options="options" :pre-selected="preSelectedCheckboxSearch" v-on:update:options="updateFilter" />
  </div>
</template>

<script>
import Checkboxes from '../form-fields/Checkboxes'
import RadioButtons from '../form-fields/RadioButtons'
import CheckboxSearch from '../form-fields/CheckboxSearch'

export default {
  name: 'v-filter',

  components: { Checkboxes, RadioButtons, CheckboxSearch },

  props: {
    id: {
      required: true,
      type: String
    },
    gaId: {
      type: String
    },
    name: {
      type: String
    },
    options: {
      required: true,
      type: Array // [ { id: String, title: String } ]
    },
    preSelected: {
      type: Array // [ String ]
    },
    resetting: true,
    title: {
      type: String
    },
    textClear: {
      type: String
    },
    type: {
      required: true,
      type: String
    }
  },

  data() {
    return {
      clearIndex: 0
    }
  },

  computed: {
    preSelectedCheckboxSearch() {
      return Array.isArray(this.preSelected) && this.preSelected.length ? this.preSelected[0] : null
    },

    updatedGaId() {
      return `${this.gaId} - Filter title: ${this.title}`
    }
  },
  created() {
    if (this.preSelected) { this.addPreSelectedToActiveOptions() }


  },

  methods: {
    addPreSelectedToActiveOptions() {
      const preselected = this.type == 'checkbox-search' ? this.preSelectedCheckboxSearch : this.preSelected

      this.updateFilter(preselected)
    },

    clearFilterOptions() {
      this.clearIndex = this.clearIndex + 1
    },

    updateFilter(updatedOptions) {
      let options = updatedOptions

      if (this.type === 'radio') {
        options = updatedOptions ? [updatedOptions] : []
      }
      const data = {
        id: this.id,
        options
      }
      this.$emit('update:filter', data)
    }
  }
}
</script>