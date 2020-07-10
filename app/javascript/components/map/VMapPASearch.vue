<template>
  <div class="v-map-pa-search">
    <input
      ref="input"
      class="v-map-pa-search__input"
      type="text"
      :placeholder="type.placeholder"
      v-model="query"
      @input="onInput"
      @keyup.enter.prevent="onEnter"
    />
    <div class="v-map-pa-search__search_icon" @click="onIconClick" />
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
      autocompleteResults: [],
    };
  },

  props: {
    type: {
      type: Object,
      required: true,
      validator: type => {
        return type.hasOwnProperty('id') &&
          type.hasOwnProperty('placeholder')
      }
    }
  },

  computed: {
    hasValidQuery() {
      return this.query && this.query.length > 2;
    }
  },

  methods: {
    onInput(e) {
      this.$emit("input", e.target.value);
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
      return axios.post("/search/autocomplete", {
        type: this.type.id,
        search_term: this.query
      });
    }
  }
};
</script>