<template>
  <div>
    <div class="flex flex-wrap flex-column">
      <p 
        v-for="option in options"
        :key="inputId(option)"
        class="checkbox no-margin"
      >

        <input
          :id="inputId(option)"
          @change="changeInput($eventHub)"
          class="checkbox__input"
          type="checkbox"
          :value="option.id"
          v-model="input"
          
        >

        <label
          :for="inputId(option)"
          class="checkbox__label no-margin flex flex-v-center"
        >
          {{ option.title }}
        </label>
      </p>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Checkboxes',

  props: {
    id: { 
      type: String,
      required: true 
    },
    options: { 
      type: Array, // { id: String, title: String }
      required: true 
    }
  },

  data () {
    return {
      input: [],
      resetting: false
    }
  },

  created () {
    this.$eventHub.$on('reset-search', this.reset)
  },

  methods: {
    changeInput () {
      if(this.resetting) { 
        this.resetting = false
        return false
      }

      this.$emit('update:options', this.input)
    },
    
    inputId (option) {
      return `${this.name}-${option.id}`
    },

    reset () {
      this.resetting = true
      this.changeInput(this.input = [])
    }
  }
}
</script>
