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
          v-for="(area, index) in protectedAreas"
          :key="index"
          class="select--dropdown__option"
          @click="selectArea(index)"
        >{{ area.title }}</span>
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
    protectedAreas: {
      type: Array
    }
  },

  data() {
    return {
      isActive: false,
      selected: this.protectedAreas[0]
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
    selectArea(index) {
        this.selected = this.protectedAreas[index];
        this.close();
        this.$emit('pa-selected', this.selected);
    }
  }
};
</script>

