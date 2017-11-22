<template>
  <div class="twitter-share" :style="styleObject" :class="{ 'twitter-share--active' : isActive }">
    <span class="twitter-share__title">Share quote via</span>
    <a 
      title="Share highlighted quote on Twitter"
      target="_blank"
      :href="twitterUrl"
      class="social--share social--twitter">
    </a>

    <a 
      title="Share highlighted quote by Email"
      target="_self"
      :href="emailUrl"
      class="social--share social--email">
    </a>
  </div>
</template>

<script>
  module.exports = {
    name: 'twitter-share',

    data: function () {
      return {
        charLimit: 140,
        watchingMouseUp: false,
        quote: '',
        url: '',
        isActive: false,
        styleObject: {
          top: 0,
          left: 0,
        }
      }
    },

    mounted: function () {
      this.getPageUrl()
      this.addListeners()
    },

    computed: {
      twitterUrl: function () {
        const quoteLimit = this.charLimit - 6 // the 6 is for "" ... and a space 
        let quote = this.quote

        if (quote.length > quoteLimit) {
          quote = '"' + quote.substring(0, quoteLimit) + '..." '
        }

        return 'https://twitter.com/intent/tweet/?text=' + quote + '&amp;url=' + this.url 
      },

      emailUrl: function () {
        return 'mailto:?subject=Marine%20Protected%20Planet%20website&amp;body=' + this.quote + '%0D%0A%0D%0A' + this.url
      }
    },

    methods: {
      getPageUrl: function () {
        const href = window.location.href

        this.url = href.split('#')[0]
      },

      addListeners: function () {
        const that = this

        // listen for text being selected
        document.addEventListener("selectionchange", function() {

          // add flag to make sure that the mouse up listener is only added once 
          // whilst the user is highlighting text
          if (!that.watchingMouseUp) {
            that.watchingMouseUp = true
            
            // listen for when the user stops highlighting text
            document.addEventListener("mouseup", function(e) {

              // get selected text
              const selected = window.getSelection().toString()

              // remove flag
              that.watchingMouseUp = false

              // only update the quote and show the share box if the selected text isn't blank
              // otherwise hide the twitter share pop up
              if (selected.length > 0) {
                const textPosition = window.getSelection().getRangeAt(0).getBoundingClientRect()
                const top = window.pageYOffset + textPosition.top - 5
                const left = textPosition.left + ( .5 * textPosition.width)

                that.isActive = true
                that.styleObject.top = top + 'px'
                that.styleObject.left = left + 'px'
                that.quote = selected  

              } else {
                that.isActive = false
              }
            }, { once: true })
          }
        }, false)
      }
    } 
  }
</script>