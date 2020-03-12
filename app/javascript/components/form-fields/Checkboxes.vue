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
            type="checkbox"
            :value="option.title"
            v-model="input"
          >
          
          <span class="checkbox__input-fake" />
        
          {{ option.title }}
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
    }
  },

  data () {
    return {
      input: []
    }
  },

  created () {
    this.$eventHub.$on('reset:filter-options', this.reset)
  },

  methods: {
    changeInput () {
      this.$emit('update:options', this.input)
    },
    
    inputId (title) {
      return `${this.id}-${title}`
    },

    reset () {
      console.log('reset checkbox')
      this.input = []
    }
  }
}
</script>
