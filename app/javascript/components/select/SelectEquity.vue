<template>
  <div class="select--equity">
    <div class="select--equity__content">
      <!-- <img :src="selected.image" :alt="'Visual results for ' + selected.title" /> -->
    </div>

    <div class="select--equity__panel">
      <h2 class="select--equity__header">Results from study sites</h2>
      <p class="select--equity__description">Lorem ipsum dolor, sit amet consectetur adipisicing elit. Esse recusandae deserunt saepe placeat ut architecto optio nostrum dolorem, laudantium ullam provident similique consectetur id eligendi praesentium labore quisquam atque vel?</p>
      <select class="select--equity__select" v-model="selected">
        <option 
          v-for="(option, index) in options" 
          :key="index" 
          :value="option"
        >
          {{ option.label }}
        </option>
      </select>
      <a
        :href="selected.url"
        class="button--view-pa"
        title="View the protected area"
      >View Protected Area</a>
    </div>
  </div>
</template>

<script>
export default {
  name: "select-equity",

  props: {
    options: {
      type: Array
    }
  },

  data() {
    return {
      selected: this.options[0]
    };
  }
};
</script>