<template>
  <div class="equity-select">
    <div class="equity-select__content">
      <img :src="selected.image" :alt="'Visual results for ' + selected.title" />
    </div>

    <div class="equity-select__panel">
      <p>Lorem ipsum dolor, sit amet consectetur adipisicing elit. Esse recusandae deserunt saepe placeat ut architecto optio nostrum dolorem, laudantium ullam provident similique consectetur id eligendi praesentium labore quisquam atque vel?</p>
      <select v-model="selected">
        <option v-for="(option, index) in options" :key="index" :value="option">{{ option.title }}</option>
      </select>
      <a :href="selected.url" title="View the protected area">View the protected area</a>
    </div>
  </div>
</template>

<script>
export default {
  name: "equity-select",

  props: {
    options: {
      type: Array
    }
  },

  data() {
    return {
      selected: null
    };
  }
};
</script>