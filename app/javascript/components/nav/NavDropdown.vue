<template>
  <div
    class="nav__dropdown"
    :class="{'active': isActive}"
  >
    <button 
      :id="mixinTriggerId"
      aria-haspopup="true"
      :aria-expanded="isActive"
      :aria-controls="mixinModalId"
      class="nav__dropdown-toggle hover--pointer flex-inline flex-v-center"
      @mouseenter="openDropdown"
    >
      <label :for="mixinModalId">
        <nav-link 
          :link="link" 
          :class="[{'active': isActive}, 'nav__dropdown-toggle-a']"
          v-touch="toggleDropdown"
        />
      </label>
      <span class="drop-arrow arrow-svg" />
    </button>
    <nav
      :id="mixinModalId"
      class="nav__dropdown-wrapper"
      :class="{'active': isActive}"
      @mouseleave="closeDropdown"
    >
      <nav-link
        v-for="dropdownLink in link.children"
        :key="dropdownLink.id"
        class="nav__dropdown-a"
        :link="dropdownLink"
      />
    </nav>
  </div>
</template>

<script>
import NavLink from './NavLink'
import mixinFocusCapture from '../../mixins/mixin-focus-capture'
import mixinPopupCloseListeners from '../../mixins/mixin-popup-close-listeners'

export default {
  name: 'nav-dropdown',

  components: {
    NavLink
  },

  mixins: [
    mixinFocusCapture({toggleVariable: 'isActive', closeCallback: 'closeDropdown', openCallback: 'openDropdown'}),
    mixinPopupCloseListeners({closeCallback: 'closeDropdown'})
  ],

  props: {
    link: {
      required: true,
      type: Object
    }
  },

  data() {
    return {
      isActive: false
    }
  },

  computed: {
    mixinModalId () {
      return `nav-dropdown-${this.link.id}`
    },

    mixinTriggerId () {
      return `nav-dropdown-toggle-${this.link.id}`
    }
  },

  methods: {
    closeDropdown () {
      this.isActive = false
    },
    openDropdown () {
      this.isActive = true
    },
    toggleDropdown (e) {
      e.preventDefault()
      this.isActive ? this.closeDropdown(e) : this.openDropdown(e)
    }
  }
}
</script>