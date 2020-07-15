<template>
  <div class="select-equity">
    <div class="select-equity__content">
      <!-- <img :src="selected.image" :alt="'Visual results for ' + selected.title" /> -->
    </div>

    <div class="select-equity__panel">
      <h2>Results from study sites</h2>
      <p>Lorem ipsum dolor, sit amet consectetur adipisicing elit. Esse recusandae deserunt saepe placeat ut architecto optio nostrum dolorem, laudantium ullam provident similique consectetur id eligendi praesentium labore quisquam atque vel?</p>
      <select v-model="selected">
        <option v-for="(option, index) in options" :key="index" :value="option">{{ option.label }}</option>
      </select>
      <a :href="selected.url" title="View the protected area">View the protected area</a>
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