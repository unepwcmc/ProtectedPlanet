<template>
  <div class="nav">
    <div :id="mixinModalId" class="nav__pane" :class="navType">

      <button id="close-nav-pane" class="nav__close" v-show="isBurgerNav" @click="closeNavPane"></button>

      <ul aria-label="nav" role="menubar" class="nav__ul v-nav-pane-target">
        <li role="none" class="nav__li" v-for="link in links" :key="link.id">
          
          <nav-dropdown v-if="hasChildren(link)" :link="link" />

          <nav-link v-else :link="link" />
        </li>
      </ul>

    </div>

    <button :id="mixinTriggerId" class="nav__burger" v-show="isBurgerNav" @click="openNavPane"></button>
  </div>
</template>

<script>
import NavDropdown from "./NavDropdown"
import NavLink from "./NavLink"
import mixinResponsive from "../../mixins/mixin-responsive"
import mixinPopupCloseListeners from "../../mixins/mixin-popup-close-listeners"
import mixinFocusCapture from "../../mixins/mixin-focus-capture"
import { disableTabbing, reenableTabbing } from '../../helpers/focus-helpers';

export default {
  name: 'nav-burger',

  components: {
    NavDropdown, NavLink
  },

  mixins: [
    mixinResponsive, 
    mixinPopupCloseListeners({closeCallback: 'closeNavPane', toggleVariable: 'isNavPaneActive'}), 
    mixinFocusCapture({toggleVariable: 'isNavPaneActive', closeCallback: 'closeNavPane', openCallback: 'openNavPane'})
  ],

  props: {
    links: { //[ { id: String, label: String, url: String } ]
      required: true,
      type: Array
    },
    isAlwaysBurger: {
      default: false,
      type: Boolean
    }
  },

  data () {
    return {
      isNavPaneActiveData: false,
      selectedDropdownId: null,
      mixinModalId: 'nav-pane',
      mixinTriggerId: 'open-nav-pane'
    }
  },

  mounted () {
    this.areNavPaneItemsVisible ? reenableTabbing(this.navPaneItemContainer) : disableTabbing(this.navPaneItemContainer)
  },

  methods: {
    openNavPane () {
      this.isNavPaneActiveData = true
    },
    
    closeNavPane () {
      this.isNavPaneActiveData = false
    },

    clickNavLink (id) {
      this.closeNavPane()
      this.scroll(id)
    },

    hasChildren (link) {
      return link.hasOwnProperty('children')
    }
  },

  computed: {
    isBurgerNav () {
      return this.isAlwaysBurger || !this.isLarge()
    },

    navType () {
      return { 
        'nav-pane--active': this.isNavPaneActive
      }
    },

    navPaneItemContainer () {
      return this.$el.querySelector('.v-nav-pane-target')
    },

    isNavPaneActive () {
      return this.isNavPaneActiveData && this.isBurgerNav
    },

    areNavPaneItemsVisible () {
      return !this.isBurgerNav || this.isNavPaneActive
    }
  },

  watch: {
    areNavPaneItemsVisible (visible) {
      visible ? reenableTabbing(this.navPaneItemContainer) : disableTabbing(this.navPaneItemContainer)
    }
  }
}
</script>