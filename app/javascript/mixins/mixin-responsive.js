export default {
  data () {
    return {
      windowWidth: 0,
      currentBreakpoint: '',
      breakpoints: {
        small: 768, // MUST MATCH VARIABLES IN assets/stylesheets/_settings
        medium: 1024,
        large: 1200
      }
    }
  },

  created () {
    this.updateWindowSize()

    // allow for multiple functions to be called on window resize
    // window.addEventListener('resize', () => this.$eventHub.$emit('windowResized'))

    this.$eventHub.$on('windowResized', this.updateWindowSize)
  },

  methods: {
    updateWindowSize () {
      this.windowWidth = window.innerWidth

      if(this.isSmall()) { this.currentBreakpoint = 'small' }
      if(this.isMedium()) { this.currentBreakpoint = 'medium' }
      if(this.isLarge()) { this.currentBreakpoint = 'large' }
      if(this.isXLarge()) { this.currentBreakpoint = 'xlarge' }
    },

    isSmall () {
      return this.windowWidth <= this.breakpoints.small
    },

    isMedium () {
      return this.windowWidth > this.breakpoints.small && this.windowWidth <= this.breakpoints.medium
    },

    isLarge () {
      return this.windowWidth > this.breakpoints.medium && this.windowWidth <= this.breakpoints.large
    },

    isXLarge () {
      return this.windowWidth > this.breakpoints.large
    },

    getCurrentBreakpoint () {
      return this.currentBreakpoint
    }
  }
}
