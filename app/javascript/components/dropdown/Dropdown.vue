<template>
  <div class="ct-dropdown">
    <span v-text="title" class="ct-dropdown__title" />
    <div class="ct-dropdown__container"  v-click-outside="closeOptions">
      <button class="ct-dropdown__button" @click="toggle"> 
        <span v-text="dropdownText" class="ct-dropdown__chosen-value" />
        <arrow class="ct-dropdown__icon" />
      </button>
      <options v-if="openOptions" :options="options" @click="chooseOption"/>
    </div>
  </div>
</template>

<script>
import Arrow from '../icon/Arrow.vue'
import Options from './Options.vue'

export default {
  name: "dropdown",
  components: {
    Options,
    Arrow
  },
  props: {
    value: {
      type: String,
      default: undefined
    },
    title: {
      type: String,
      default: undefined
    },
    defaultDropdownText: {
      type: String,
      default: undefined
    },
    options: {
      type: Array,
      required: true
    }
  },
  data(){
    return {
      openOptions: false
    }
  },
  computed: {
    dropdownText(){

      return this.value ?? this.defaultDropdownText
    }
  },
  methods: {
    chooseOption(option) {
      this.$emit("input", option);
      this.openOptions = false
    },
    toggle(){
      console.log("Hi");
      
      this.openOptions = !this.openOptions;
    },
    closeOptions(){
      this.openOptions = false
    }
  }
}
</script>