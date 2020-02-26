<template>
  <div>
    <div class="flex flex-wrap flex-column">
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
  </div>
</template>

<script>
export default {
  name: 'radio-buttons',

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
      input: '',
      resetting: false
    }
  },

  created () {
    this.changeInput(this.options[0].id)
    this.$eventHub.$on('reset-search', this.reset)
  },

  methods: {
    changeInput (id) {
      if(this.resetting) { 
        this.resetting = false
        return false
      }

      this.input = id

      this.$emit('update:options', this.input)
    },

    radioId (option) {
      return `${this.name}-${option.id}}`
    },

    reset () {
      this.resetting = true
      this.changeInput(this.options[0].id)
    }
  }
}
</script>
