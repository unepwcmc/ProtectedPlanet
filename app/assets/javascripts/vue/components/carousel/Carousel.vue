<template>
  <aside class="carousel" aria-labelledby="carousel-heading">

    <template v-if="title">
      <h1 id="carousel-heading">{{ title }}</h1>
    </template>

    <template v-if="showCount">
      <h2>{{ currentSlide }} of {{ totalSlides }}</h2>
    </template>

    <div class="carousel__slides-container">
      <ul id="carousel-slides" class="carousel__slides">
        <template v-for="n in 3">
          <slot :slidesScope="slidesScope"></slot>
        </template>
      </ul>
    </div>
    <div class="carousel__indicators">
      <button
        v-for="slide in totalSlides"
        class="carousel__indicator"
        :class="selectedSlideClass(slide)"
        @click="changeSlide(slide)"></button>
    </div>
  </aside>
</template>

<script>
const helpers = require('./carousel-helpers')
//TODO: permenant title offscreen for accessibility?
module.exports = {
  name: 'carousel',

  props: {
    showCount: {
      default: false,
      type: Boolean
    },
    title: String,
    slideIntervalLength: {
      default: 0,
      type: Number
    }
  },

  data() {
    return {
      currentSlide: 1,
      totalSlides: 0,
      childSlideComponents: this.$children,
      nextSlideInterval: {},
      containerWidth: 0,
      slideWidth: 0,
      // slidesEl: {},
      slidesScope: {}
    }
  },

  created() {
    window.onresize = () => {
      this.setSlideWidth()
      this.setSlideTransforms()
    }
  },

  computed: {
    // totalFrames () {
    //   return Math.ceil(this.totalSlides / Math.floor(this.containerWidth / this.slideWidth))
    // }
  },

  mounted () {
    this.totalSlides = this.childSlideComponents.length / 3
    this.addIndices()
    this.setSlideWidth()
    this.setContainerWidth()
    this.setOrders()
    this.setSlideTransforms()
    if (this.slideIntervalLength) { this.setSlideInterval() }
    // this.slidesEl = this.$el.querySelector('#carousel-slides')
  },

  methods: {
    addIndices () {
      this.childSlideComponents.forEach( (child, index) => {
        const realIndex = index % this.totalSlides

        child.index = realIndex
      })
    },

    setOrders () {
      this.childSlideComponents.forEach( (child, index) => {
        child.order = index
      })
    },

    shiftOrders (changeInIndex) {
      this.childSlideComponents.forEach((child, index) => {
        const newOrderBeforeMod = child.order - changeInIndex

        if (newOrderBeforeMod < 0) {
          child.order = newOrderBeforeMod + this.totalSlides * 3
        } else if (newOrderBeforeMod > this.totalSlides * 3 - 1) {
          child.order = newOrderBeforeMod - this.totalSlides * 3
        } else {
          child.order = newOrderBeforeMod
        }
      })
    },

    setSlideWidth () {
      this.slideWidth = this.getWidthWithMargins(this.childSlideComponents[0].$el)
    },

    setContainerWidth () {
      this.containerWidth = this.$el.offsetWidth
    },

    //TODO: export to helper
    getWidthWithMargins (element) {
      const style = element.currentStyle || window.getComputedStyle(element)
      
      return element.offsetWidth + parseInt(style.marginLeft, 10) + parseInt(style.marginRight, 10)
    },

    setSlideIntervalIfConfigured () {
      if (this.slideIntervalLength) {
        this.setSlideInterval()
      }
    },

    setSlideInterval () {
      this.nextSlideInterval = setInterval(() => {
        this.setNextSlide(true)
      }, this.slideIntervalLength)
    },

    setNextSlide (isAuto=false) {
      if (this.currentSlide === this.totalSlides) {
        this.changeSlide(1, isAuto)
      } else {
        this.changeSlide(this.currentSlide + 1, isAuto)
      }
    },

    changeSlide (slide, isAuto=false) {
      const directSlideDisplacement = slide - this.currentSlide
      let indirectSlideDistance;
      let changeInIndex;

      if (directSlideDisplacement > 0) {
        indirectSlideDistance = this.currentSlide + this.totalSlides - slide
      } else {
        indirectSlideDistance = this.totalSlides - this.currentSlide + slide
      }

      if (Math.abs(directSlideDisplacement) > indirectSlideDistance) {
        changeInIndex = indirectSlideDistance * -directSlideDisplacement/Math.abs(directSlideDisplacement)
      } else {
        changeInIndex = directSlideDisplacement
      }

      this.slideBy(changeInIndex)
      this.currentSlide = slide

      if (!isAuto && this.slideIntervalLength) {
        this.resetSlideInterval()
      }
    },

    slideBy (changeInIndex) {
      this.shiftOrders(changeInIndex)
      this.setSlideTransforms()
    },

    setSlideTransforms () {
      this.childSlideComponents.forEach(child => {
        const newLeft = (child.order - this.totalSlides) * this.slideWidth
        let transition = child.$el.style.transition

        if (newLeft * parseInt(child.$el.style.left) < 0) {
          child.$el.style.transition = 'none'

          setTimeout(() => {
            child.$el.style.transition = transition
          })
        }

        child.$el.style.left = newLeft + 'px'
      })
    },

    resetSlideInterval () {
        clearInterval(this.nextSlideInterval)
        this.setSlideIntervalIfConfigured()
    },

    selectedSlideClass (slide) {
      return {'carousel__indicator--selected' : this.isCurrentSlide(slide)}
    },

    isCurrentSlide (slide) {
      return slide === this.currentSlide
    }
  }
}
</script>
