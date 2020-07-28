export default {
  // Check if total height of options in dropdown (when active) exceeds 40vh (as an arbitrary threshold)
  // If so, do nothing
  // If not, reduce height of dropdown list div to match total height of options
  computed: {
    restrictHeight(element) {
      const height = document.getElementsByClassName(element).getAttribute('height');
      const threshold = 0.4 * window.innerHeight;
      if (height < threshold) {
        document.querySelector()
      }
    }
  }
}