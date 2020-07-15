<template>
  <div class="select--equity">
    <div class="select--equity__content">
      <!-- Todo: Images aren't present in the CMS pages as of yet, might need to rescue with a placeholder -->
      <!-- <img :src="selected.image" :alt="'Visual results for ' + selected.title" /> -->
    </div>

    <div class="select--equity__panel">
      <h2 class="select--equity__header">Results from study sites</h2>
      <p
        class="select--equity__description"
      >Lorem ipsum dolor, sit amet consectetur adipisicing elit. Esse recusandae deserunt saepe placeat ut architecto optio nostrum dolorem, laudantium ullam provident similique consectetur id eligendi praesentium labore quisquam atque vel?</p>
      <select-dropdown 
        :options="options"
        @pa-selected="changeSelection"
      />
      <a
        :href="selected.url"
        class="button--view-pa"
        title="View the protected area"
      >View Protected Area</a>
    </div>
  </div>
</template>

<script>
import SelectDropdown from './SelectDropdown';

export default {
  name: "select-equity",
  components: { SelectDropdown },
  props: {
    options: {
      type: Array
    }
  },

  data() {
    return {
      selected: this.options[0]
    };
  },
  methods: {
    changeSelection(selected) {
      this.selected = selected;
    }
  }
};
</script>