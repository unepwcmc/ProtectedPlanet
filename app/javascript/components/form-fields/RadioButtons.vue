<template>
  <div 
    class="flex flex-wrap flex-column"
    v-show="options" 
  >
    <p 
      v-for="option in options"
      :key="radioId(option)"
      class="radio no-margin"
    >
      
      <label
        :for="radioId(option)"
        class="radio__label no-margin flex flex-v-center"
      >
        <input
          :id="radioId(option)"
          v-model="input"
          required
          type="radio"
          class="radio__input"
          :value="option.id"
          :name="name"
          @click="changeInput(option.id)"
        />
        
        <span class="radio__input-fake" />
        
        {{ option.title }}
      </label>
    </p>
  </div>
</template>

<script>
export default {
  name: 'radio-buttons',

  props: {
    clearIndex: {
      type: Number
    },
    id: { 
      type: String,
      required: true 
    },
    name: { 
      type: String,
      required: true 
    },
    options: { 
      default: () => [],
      type: Array // { id: String, title: String }
    },
    preSelected: {
      default: '',
      type: String
    }
  },

  data () {
    return {
      input: '',
    }
  },

  created () {
    this.changeInput(this.preSelected)  

    this.$eventHub.$on('reset:filter-options', this.reset)
  },

  watch: {
    clearIndex () {
      this.reset()
      this.changeInput()
    }
  },

  methods: {
    changeInput (id) {
      this.input = id

      this.$emit('update:options', this.input)
    },

    radioId (option) {
      return `${this.name}-${option.id}}`
    },

    reset () {
      this.input = ''
    }
  }
}
</script>
