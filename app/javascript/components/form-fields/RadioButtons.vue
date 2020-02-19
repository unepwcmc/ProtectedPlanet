<template>
  <div>
    <div class="flex flex-wrap flex-column">
      <p 
        v-for="option in options"
        :key="radioId(option)"
        class="radio no-margin"
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
        >

        <label
          :for="radioId(option)"
          class="radio__label no-margin flex flex-v-center"
        >
          {{ option.title }}
        </label>
      </p>
    </div>
  </div>
</template>

<script>
export default {
  name: 'RadioButtons',

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
    radioId (option) {
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
