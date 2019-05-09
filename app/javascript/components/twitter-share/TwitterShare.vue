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
  export default {
    name: 'twitter-share',

    data () {
      return {
        twitterHandle: 'protectedplanet',
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

    mounted () {
      this.getPageUrl()
      this.addListeners()
    },

    computed: {
      twitterUrl () {
        const quoteLimit = this.charLimit - 6 - this.twitterHandle.length - 5 // the 6 is for "" ... and 1 space // the 5 is for via and 2 spaces
        const quote = this.quote

        if (quote.length > quoteLimit) {
          quote = quote.substring(0, quoteLimit) + '...'
        }

        const text = this.addQuoteMarks(quote)

        return encodeURI('https://twitter.com/intent/tweet/?text=' + text + '&url=' + this.url + '&via=' + this.twitterHandle)
      },

      emailUrl () {
        const text = this.addQuoteMarks(this.quote)

        return encodeURI('mailto:?subject=Marine Protected Planet&body=' + text + '\n\n' + this.url)
      }
    },

    methods: {
      getPageUrl () {
        const href = window.location.href

        this.url = href.split('#')[0]
      },

      addQuoteMarks (text) {
        return '"' + text + '"'
      },

      addListeners () {
        // listen for text being selected
        document.addEventListener("selectionchange", () => {

          // add flag to make sure that the mouse up listener is only added once
          // whilst the user is highlighting text
          if (!this.watchingMouseUp) {
            this.watchingMouseUp = true

            // listen for when the user stops highlighting text
            document.addEventListener("mouseup", (e) => {

              // get selected text
              const selected = window.getSelection().toString()

              // remove flag
              this.watchingMouseUp = false

              // only update the quote and show the share box if the selected text isn't blank
              // otherwise hide the twitter share pop up
              if (selected.length > 0) {
                const textPosition = window.getSelection().getRangeAt(0).getBoundingClientRect(),
                  top = window.pageYOffset + textPosition.top - 5,
                  left = textPosition.left + ( .5 * textPosition.width)
                
                this.isActive = true
                this.styleObject.top = top + 'px'
                this.styleObject.left = left + 'px'
                this.quote = selected

              } else {
                this.isActive = false
              }
            }, { once: true })
          }
        }, false)
      }
    }
  }
</script>
