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
          v-model="input"
          required
          type="checkbox"
          class="checkbox__input"
          :value="option.id"
          :name="name"
          @click="changeInput(option.id)"
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
    },
    name: { 
      type: String,
      required: true 
    }
  },

  data () {
    return {
      input: ''
    }
  },

  created () {
    this.changeInput(this.options[0].id, this.options[0].slug)
    this.$eventHub.$on('resetForm', this.reset)
  },

  methods: {
    inputId (option) {
      return `${this.name}-${option.id}}`
    },

    friendly (string) {
      return string.toLowerCase().replace(' ', '-')
    },

    labelClass (string) {
      return 'radio-button__label-' + this.friendly(string)
    },

    changeInput (id) {
      this.input = id

      this.$emit('update:selected-option', id)
    },

    reset () {
      this.changeInput(this.options[0].id)
    }
  }
}
</script>
