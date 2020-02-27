<template>
  <div
    class="search--autocomplete"
  >
    <div class="search__search">
      <i class="search__search-icon" /> 

      <input
        v-model="searchTerm"
        class="search__search-input"
        type="text"
        :placeholder="placeholder"
        v-on:keyup="updateAutocomplete"
        v-on:keyup.enter="submit"
      >
    </div>

    <button 
      v-show="showResetIcon"
      class="search__search-icon--delete"
      @click="resetSearchTerm"
    />

    <ul 
      v-show="autocomplete.length > 0" 
      role="listbox" 
      class="search__dropdown"
    >
      <li
        v-for="(option, index) in autocomplete"
        :key="option.id"
        class="search__li"
        role="option"
      >
        <a 
          class="search__a"
          :href="option.url"
          v-html="option.title"
        />
      </li>
    </ul>

    <div class="select--types">
      <label 
        v-if="hasMultipleTypes"
        :class="['select__label', {'active': typeDropdownActive}]"
        @click="toggleTypes"
        v-html="selectedTypeName"
      />
      <p 
        v-else
        class="select__label-fake"
        v-html="selectedTypeName"
      />

      <ul 
        v-if="hasMultipleTypes"
        :class="['select__ul', {'active': typeDropdownActive}]"
      >
        <li 
          v-for="type, index in types"
          class="select__li"
          @click="updateType(type)"
        >
          {{ type.name }}
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
import axios from 'axios'
import mixinAxiosHelpers from '../../mixins/mixin-axios-helpers'
import mixinPopupCloseListeners from '../../mixins/mixin-popup-close-listeners'

export default {
  name: 'search-areas-input-autocomplete',

  mixins: [
    mixinAxiosHelpers,
    mixinPopupCloseListeners({closeCallback: 'closeSelect'}),
  ],

  props: {
    types: {
      required: true,
      type: Array // [ { name: String, options: [ { id: Number, name: String } ] } ]
    },
    endpoint: {
      required: true,
      type: String
    }
  },

  data () {
    return {
      autocomplete: [], // [ { title: String, url: String } ]
      placeholder: '',
      searchTerm: '',
      typeDropdownActive: false,
      typeIndex: 0,
    }
  },

  computed: {
    hasAutocompleteOptions () {
      return this.autocomplete.length > 0
    },
    hasMultipleTypes () {
      return this.types.length > 1
    },
    options () {
      return this.types[this.typeIndex].options
    },
    searchParams () {
      return {
        type: this.selectedTypeName,
        search_term: this.searchTerm
      }
    },
    selectedTypeName () {
      return this.types[this.typeIndex].name
    },
    showResetIcon () {
      return this.searchTerm.length != 0
    }
  },

  mounted () {
    // this.addTabFromSearchListener()
    // this.addArrowKeyListeners()
    // this.addTabForwardFromResetListener()
  },

  methods: {
    updateAutocomplete (e) {
      if(this.searchTerm.length < 3 || e.key == 'Enter') { 
        this.resetAutocomplete() 
        return false
      }

      let data = { params: this.searchParams }

      this.axiosSetHeaders()

      axios.post(this.endpoint, data)
      .then(response => {
        this.autocomplete = response.data
      })
      .catch(function (error) {
        console.log(error)
      })
    },

    updateType (type) {
      this.type = type.name
      this.placeholder = type.placeholder
      this.toggleTypes()
      this.resetSearchTerm()
      this.resetAutocomplete()
    },

    toggleTypes () {
      if(!this.hasMultipleTypes) { return false }

      this.typeDropdownActive = !this.typeDropdownActive
    },

    resetSearchTerm () {
      this.searchTerm = ''
      this.resetAutocomplete()
    },

    resetAutocomplete () {
      this.autocomplete = []
    },

    submit () {
      this.$emit('submit-search', this.searchParams)
    }
  }
}
</script>