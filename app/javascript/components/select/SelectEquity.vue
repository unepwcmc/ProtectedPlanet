<template>
  <!--  As of 14May2025 NC decided not to show the chart -->
  <div class="select--equity">
    <div class="select--equity__content">
      <img :src="selected.image" :alt="'Visual results for ' + selected.title" />
    </div>

    <div class="select--equity__panel">
      <h2 class="select--equity__header">Results from study sites</h2>
      <p class="select--equity__description">{{ selected.text }}</p>
      <select-dropdown :protected-areas="protectedAreas" @pa-selected="changeSelection" />
      <a
        v-show="selected.url"
        :href="selected.url"
        class="button--primary select--equity__button"
        title="View the protected area"
      >View Protected Area</a>
    </div>
  </div>
</template>

<script>
import SelectDropdown from "./SelectDropdown";

export default {
  name: "select-equity",
  components: { SelectDropdown },
  props: {
    protectedAreas: {
      type: Array
    }
  },

  data() {
    return {
      selected: this.protectedAreas[0]
    };
  },
  methods: {
    changeSelection(selected) {
      this.selected = selected;
    }
  }
};
</script>