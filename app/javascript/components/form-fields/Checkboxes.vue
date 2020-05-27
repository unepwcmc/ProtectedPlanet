<template>
  <div>
    <div class="flex flex-wrap flex-column">
      <p 
        v-for="option, index in options"
        :key="index"
        class="checkbox no-margin"
      >
        <label
          :for="inputId(option.title)"
          class="checkbox__label no-margin flex flex-v-center"
        >
          <input
            :id="inputId(option.title)"
            @change="changeInput($eventHub)"
            class="checkbox__input"
            :checked="isChecked(option.id)"
            type="checkbox"
            :value="option.id"
            v-model="input"
          >
          
          <span class="checkbox__input-fake" />
        
          <span class="checkbox__text">{{ option.title }}</span>
        </label>
      </p>
    </div>
  </div>
</template>

<script>
export default {
  name: 'checkboxes',

  props: {
    id: { 
      type: String,
      required: true 
    },
    options: { 
      type: Array, // { title: String }
      required: true 
    },
    preSelected: {
      type: String
    }
  },

  data () {
    return {
      input: []
    }
  },

  created () {
    if(this.preSelected) { 
      this.input.push(this.preSelected)
      this.changeInput(this.preSelected) 
    }

    this.$eventHub.$on('reset:filter-options', this.reset)
  },

  methods: {
    changeInput () {
      this.$emit('update:options', this.input)
    },
    
    inputId (title) {
      return `${this.id}-${title}`
    },

    isChecked (id) {
      return this.preSelected == id
    },

    reset () {
      this.input = []
    }
  }
}
</script>
