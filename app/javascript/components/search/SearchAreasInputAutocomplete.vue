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
        :placeholder="config.placeholder"
        v-on:keyup="updateAutocompleteDebounce"
        v-on:keyup.enter="submit"
      >
    </div>

    <button
      v-show="showResetIcon"
      class="search__search-icon--delete"
      @click="resetSearchTerm"
    />
    
    <div
      class="search__dropdown"
      v-show="autocomplete.length > 0"
    >
      <ul
        class="search__ul"
        role="listbox"
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
    </div>
  </div>
</template>

<script>
import axios from 'axios'
import mixinAxiosHelpers from '../../mixins/mixin-axios-helpers'
import mixinPopupCloseListeners from '../../mixins/mixin-popup-close-listeners'
import useCommon from '../../composables/useCommon'

const { debounceFn } = useCommon()

export default {
  name: 'search-areas-input-autocomplete',
  mixins: [
    mixinAxiosHelpers,
    mixinPopupCloseListeners({ closeCallback: 'closeSelect' }),
  ],
  props: {
    config: {
      required: true,
      type: Object // { id: String, placeholder: String }
    },
    endpoint: {
      required: true,
      type: String
    },
    prePopulatedSearchTerm: String
  },

  data () {
    return {
      autocomplete: [], // [ { title: String, url: String } ]
      searchTerm: '',
      timer: undefined
    }
  },

  computed: {
    hasAutocompleteOptions () {
      return this.autocomplete.length > 0
    },
    searchParams () {
      return {
        search_term: this.searchTerm,
        type: this.config.id
      }
    },
    showResetIcon () {
      return this.searchTerm.length != 0
    }
  },

  mounted () {
    if(this.prePopulatedSearchTerm) { this.searchTerm = this.prePopulatedSearchTerm }
  },

  watch: {
    prePopulatedSearchTerm () {
      this.searchTerm = this.prePopulatedSearchTerm
    }
  },

  methods: {
    debounce(func, timeout = 700){ 
      return (...args) => { 
        clearTimeout(this.timer);
        this.timer = setTimeout(() => { func.apply(this, args); }, timeout);
      }
    },
    updateAutocomplete (e) {
      if(e.key == 'Enter') {
        this.resetAutocomplete()
        return false
      }

      let data = this.searchParams

      this.axiosSetHeaders()

      axios.post(this.endpoint, data)
      .then(response => {
        this.autocomplete = response.data
      })
      .catch(function (error) {
        console.log(error)
      })
    },
    updateAutocompleteDebounce(e){
      debounceFn(() => this.updateAutocomplete(e))()
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
