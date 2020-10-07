export default (el, ev, handler) => {
  return {
    created () {
      el.addEventListener(ev, handler.bind(this))
    },
    beforeDestroy() {
      el.removeEventListener(ev, handler.bind(this))
    },
  }
}