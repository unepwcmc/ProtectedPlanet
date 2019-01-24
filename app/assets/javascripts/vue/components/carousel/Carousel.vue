<template>
  <div class="carousel">

    <template v-if="title">
      <h1>{{ title }}</h1>
    </template>

    <template v-if="showCount">
      <h2>{{ currentSlide }} of {{ totalSlides }}</h2>
    </template>

    <div class="carousel__slides-container">
      <div class="carousel__slides">
        <slot></slot>
      </div>
    </div>
    <div class="carousel__indicators">
      <button
        v-for="slide in totalSlides"
        class="carousel__indicator"
        :class="selectedSlideClass(slide)"
        @click="changeSlide(slide)"></button>
    </div>
  </div>
</template>

<script>
module.exports = {
  name: 'carousel',

  props: {
    showCount: {
      default: false,
      type: Boolean
    },
    title: String
  },

  data() {
    return {
      currentSlide: 1,
      totalSlides: 0,
      children: this.$children,
      nextSlideInterval: {},
      slideWidth: 0,
      slidesEl: {}
    }
  },

  mounted () {
    this.totalSlides = this.children.length
    this.addIndices()
    this.setSlideWidth()
    this.setSlideInterval()
    this.slidesEl = this.$el.querySelector('.carousel__slides')
  },

  methods: {
    addIndices () {
      this.children.forEach( (child, index) => {
        child.index = index
      })
    },

    changeSlide (slide, isAuto=false) {
      this.currentSlide = slide
      this.setSlideTransform()

      if (!isAuto) {
        this.resetSlideInterval()
      }
    },

    setNextSlide (isAuto=false) {
      if (this.currentSlide === this.totalSlides) {
        this.changeSlide(1, isAuto)
      } else {
        this.changeSlide(this.currentSlide + 1, isAuto)
      }
    },

    setSlideInterval () {
      this.nextSlideInterval = setInterval(() => {
        this.setNextSlide(true)
      }, 4000)
    },

    resetSlideInterval () {
        clearInterval(this.nextSlideInterval)
        this.setSlideInterval()
    },

    selectedSlideClass (slide) {
      return {'carousel__indicator--selected' : this.isCurrentSlide(slide)}
    },

    isCurrentSlide (slide) {
      return slide === this.currentSlide
    },

    setSlideWidth () {
      const slide = this.children[0].$el
      const style = slide.currentStyle || window.getComputedStyle(slide)

      this.slideWidth = slide.offsetWidth + parseInt(style.marginLeft, 10) + parseInt(style.marginRight, 10)
    },

    setSlideTransform () {
      const shift = (this.currentSlide - 1) * this.slideWidth

      this.slidesEl.style.transform = `translateX(-${shift}px)`
    }
  }
}
</script>
