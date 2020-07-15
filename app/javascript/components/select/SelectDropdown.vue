<template>
  <div class="select--dropdown__custom-select">
    <div class="select--dropdown__custom-select-box">
      <div class="select--dropdown__selected" @click="toggleVis">
        <span>{{ selected.title }}</span>
        <div
          :class="[ isActive ? 'select--dropdown__dropdown--active' : 'select--dropdown__dropdown' ]"
        ></div>
      </div>
      <div :class="[ isActive ? 'select--dropdown__options--active' : 'select--dropdown__options' ]">
        <span
          v-for="(option, index) in options"
          :key="index"
          class="select--dropdown__option"
          @click="selectOption(index)"
        >{{ option.title }}</span>
      </div>
    </div>
  </div>
</template>

<script>
import mixinPopupCloseListeners from "../../mixins/mixin-popup-close-listeners"

export default {
  name: "SelectDropdown",
  mixins: [ mixinPopupCloseListeners({closeCallback: 'close', toggleVariable: 'isActive'}) ],
  props: {
    options: {
      type: Array
    }
  },

  data() {
    return {
      isActive: false,
      selected: this.options[0]
    };
  },
  methods: {
    toggleVis() {
      this.isActive ? this.close() : this.open();
    },
    close() {
      this.isActive = false;
    },
    open() {
      this.isActive = true;
    },
    selectOption(index) {
        this.selected = this.options[index];
        this.close();
        this.$emit('pa-selected', this.selected);
    }
  }
};
</script>

