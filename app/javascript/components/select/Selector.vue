<template>
  <div class="selector">
    <div
      class="selector__selected"
      ref="selected"
      tabindex="0"
      @focus="showDropdown(true)"
      @click="showDropdown(true)"
      @keyup="onKeyup"
      @keyup.enter="showDropdown(true)"
    >
      <div class="selector__label">{{ state.label }}</div>
      <div
        class="selector__caret"
        :class="{
            'selector__caret--active': dropdownEnabled
        }"
      />
      <div v-if="dropdownEnabled" class="selector__options">
        <div
          class="selector__option"
          ref="options"
          tabindex="0"
          v-for="opt in computedOptions.slice(1)"
          :class="{ 'selector__option--active': isSelected(opt.value) }"
          :key="opt.value"
          @click="select(opt.value)"
          @keyup="onKeyup"
          @keyup.enter.stop="select(opt.value)"
          @keyup.esc.stop="showDropdown(false)"
          @keyup.up.prevent.stop="onKeyArrowUp(opt)"
          @keyup.down.prevent.stop="onKeyArrowDown(opt)"
        >{{ opt.label }}</div>
      </div>
    </div>
  </div>
</template>
<script>
import { delay, debounce, intersectionBy } from "lodash";

export default {
  model: {
    event: "change",
    prop: "state"
  },
  props: {
    default: {
      required: false
    },
    state: {
      required: true
    },
    options: {
      type: Array,
      required: true,
      validator: options => {
        for (var option of options) {
          if (typeof option === "string") continue;
          if (
            option instanceof Object &&
            option.hasOwnProperty("label") &&
            option.hasOwnProperty("value")
          )
            continue;
          return false;
        }
        return true;
      }
    }
  },
  created() {
    document.documentElement.addEventListener("click", this.onDocumentClick);
    if (typeof this.default !== "undefined" && !this.state) {
      this.select(this.default);
    }
  },
  beforeDestroy() {
    document.documentElement.removeEventListener("click", this.onDocumentClick);
  },
  data() {
    return {
      dropdownEnabled: false,
      search: undefined,
      searchClear: undefined
    };
  },
  computed: {
    computedOptions() {
      return [
        {
          value: undefined,
          label: ""
        },
        ...this.options.map(opt => {
          if (typeof opt === "string") return { value: opt, label: opt };
          return {
            value: opt.value,
            label: opt.label
          };
        })
      ];
    },
    defaultOption() {
      return (
        this.computedOptions.filter(
          option => option.value === this.default
        )[0] || this.computedOptions[0]
      );
    },
    optionSelected() {
      try {
        return (
          this.computedOptions.filter(opt => opt.value === this.state)[0] ||
          this.defaultOption
        );
      } catch (e) {
        console.error(e);
      }
      return this.defaultOption;
    }
  },
  watch: {
    dropdownEnabled(dropdownEnabled, previousDropdownEnabled) {
      if (dropdownEnabled && previousDropdownEnabled === false) {
        // focus the first item when the dropdown is toggled
        delay(() => this.$refs.options[0].focus(), 0); // delay fixes issue with focus
      }
    }
  },
  methods: {
    onDocumentClick(e) {
      e.preventDefault();
      e.stopPropagation();
      if (this.$el.contains(document.activeElement)) {
      } else {
        this.showDropdown(false);
      }
    },
    onKeyup(e) {
      if (this.searchClear) {
        // if there's a timeout ID, clear it
        clearTimeout(this.searchClear);
      }
      // treat keyboard input keys as literal keys if their length=1 & ignore everything else
      if (e.key.length === 1) {
        this.search = this.search ? this.search + e.key : e.key;
        const searchResult = this.computedOptions.slice(1).filter(option =>
          // when the search is length=1, match from the beginning of the labels, else match against whole label
          new RegExp(
            (this.search.length === 1 ? "^" : "") + this.search,
            "i"
          ).test(option.label)
        )[0];
        if (searchResult) {
          if (this.dropdownEnabled) {
            // focus if you have the options in front of you to choose from
            this.$refs.options[
              this.computedOptions.slice(1).indexOf(searchResult)
            ].focus();
          } else {
            // pro-actively select something if you're typing without the options to choose from
            this.select(searchResult.value);
          }
        }
      } else {
        // treat all other keys as clear signals
        this.search = undefined;
      }
      // schedule the current search string to be cleared after a set time if subsequent input is not received
      this.searchClear = delay(() => {
        this.search = undefined;
      }, 250);
    },
    onKeyArrowDown(opt) {
      const options = this.computedOptions.slice(1);
      const index = options.indexOf(opt);
      this.$refs.options[index < options.length - 1 ? index + 1 : 0].focus();
    },
    onKeyArrowUp(opt) {
      const options = this.computedOptions.slice(1);
      const index = options.indexOf(opt);
      this.$refs.options[index > 0 ? index - 1 : options.length - 1].focus();
    },
    select(value) {
      this.$emit("change", value);
      if (this.dropdownEnabled === true) {
        this.showDropdown(false);
      }
    },
    isSelected(value) {
      return this.state === value;
    },
    showDropdown(value) {
      if (typeof value === "boolean") {
        this.dropdownEnabled = value;
      } else {
        this.dropdownEnabled = !this.dropdownEnabled;
      }
    }
  }
};
</script>