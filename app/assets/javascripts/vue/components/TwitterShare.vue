<template>
  <div>
    TWitter Share
  </div>
</template>

<script>
  module.exports = {
    name: 'twitter-share',

    data: function () {
      return {
        watchingMouseUp: false
      }
    },

    mounted: function () {
      document.addEventListener("selectionchange", function(e) {
        if (!this.watchingMouseUp) {
          this.watchingMouseUp = true
          document.addEventListener("mouseup", function(e) {
            console.log('mouseup', window.getSelection().toString())
            this.watchingMouseUp = false
          }, false)
        }
      }, false)
    }
  }
</script>