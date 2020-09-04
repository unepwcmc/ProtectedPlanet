<template>
  <div>
    <div class="flex flex-wrap flex-column">
      <p 
        v-for="option in options"
        :key="option.id"
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
    clearIndex: {
      type: Number
    },
    id: { 
      type: String,
      required: true 
    },
    options: { 
      type: Array, // { title: String }
      required: true 
    },
    preSelected: {
      type: Array // [ String ]
    }
  },

  data () {
    return {
      input: []
    }
  },

  computed: {
    hasPreSelectedOptions () {
      return Array.isArray(this.preSelected) && this.preSelected.length
    }
  },

  watch: {
    clearIndex () {
      this.reset()
      this.changeInput()
    }
  },

  mounted () {
    if(this.hasPreSelectedOptions) { 
      this.input = this.preSelected
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
    
    reset () {
      this.input = []
    }
  }
}
</script>
