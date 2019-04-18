const ESCAPE_KEYCODE = 27
const closeOnClickOutside = true
const closeOnEscKeypress = true
const toggleVariable = 'isActive'

var mixinPopupCloseListeners = function (closeCallback) {
  return ({
    mounted: function () {
      if(closeOnClickOutside) {
        window.addEventListener('click', this.clickOutsideHandler)
      }

      if(closeOnEscKeypress) {
        this.$el.addEventListener('keydown', this.escKeypressHandler)
      }
    },

    methods: {
      clickOutsideHandler: function (e) {
        if (this[toggleVariable] && !this.$el.contains(e.target)) { this[closeCallback](e) }
      },

      escKeypressHandler: function (e) {
        if (e.keyCode === ESCAPE_KEYCODE) { 
          if(this[toggleVariable]) {
            this[closeCallback](e)
            e.stopPropagation()
          }
        }
      }
    },

    beforeDestroy: function () {
      window.removeEventListener('click', this.clickOutsideHandler)
      window.removeEventListener('keydown', this.escKeypressHandler)
    }
  })
}