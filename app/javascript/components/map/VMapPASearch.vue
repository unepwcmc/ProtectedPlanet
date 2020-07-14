<template>
  <div class="v-map-pa-search__container">
    <div class="v-map-pa-search" @focus="onElementFocus">
      <input
        ref="input"
        class="v-map-pa-search__input"
        type="text"
        :placeholder="type.placeholder"
        v-model="query"
        @input="onInput"
        @keyup.enter.prevent="onEnter"
        @keyup.esc.prevent="onEscape"
      />
      <div class="v-map-pa-search__magnifying-glass" @click="onIconClick" />
    </div>
    <div class="v-map-pa-search__results-container" v-if="hasResults">
      <div class="v-map-pa-search__results">
        <div
          class="v-map-pa-search__result"
          v-for="(result, index) in autocompleteResults"
          tabindex="0"
          :key="index"
        >
          <span v-html="result"></span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from "axios";

export default {
  name: "VMapPASearch",

  model: {
    prop: "query",
    event: "search"
  },

  data() {
    return {
      query: "",
      autocompleteResults: []
    };
  },

  props: {
    type: {
      type: Object,
      required: true,
      validator: type => {
        return type.hasOwnProperty("id") && type.hasOwnProperty("placeholder");
      }
    }
  },

  computed: {
    hasValidQuery() {
      return this.query && this.query.length > 2;
    },
    hasResults() {
      return this.autocompleteResults.length > 0;
    }
  },

  methods: {
    onInput(e) {
      this.$emit("input", e.target.value);
    },

    onEscape() {
      this.resetAutocompleteResults();
    },

    resetAutocompleteResults() {
      this.autocompleteResults = [];
    },

    focusInput() {
      this.$refs.input.focus();
    },

    onIconClick() {
      if (this.query) {
        this.submitSearch();
      } else {
        this.focusInput();
      }
    },

    onElementFocus() {
      this.$refs.input.focus();
    },

    onEnter() {
      this.$emit("search", this.query);
      this.submitSearch()
        .then(results => {
          this.autocompleteResults = results;
        })
        .catch(e => {
          console.error(e);
          this.autocompleteResults = [];
        });
    },

    submitSearch() {
      return new Promise(resolve => {
        // TESTING
        setTimeout(function() {
          resolve([
            "a",
            "abc",
            "abcde",
            "a",
            "abc",
            "abcde",
            "a",
            "abc",
            "abcde",
            "a",
            "abc",
            "abcde"
          ]);
        }, 500);
      });
      // return axios.post("/search/autocomplete", {
      //   type: this.type.id,
      //   search_term: this.query
      // });
    }
  }
};
</script>