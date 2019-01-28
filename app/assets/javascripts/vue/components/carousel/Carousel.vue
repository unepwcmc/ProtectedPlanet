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
      <div v-if="showArrows" class="carousel__arrow-buttons">
        <button class="carousel__arrow carousel__arrow--left" @click="slideToPrevious()">
          <span class="fas fa-angle-left"></span>
        </button>
        <button class="carousel__arrow carousel__arrow--right" @click="slideToNext()">
          <span class="fas fa-angle-right"></span>
        </button>
      </div>
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
//TODO: permenant title offscreen for accessibility?
module.exports = {
  name: 'carousel',

  props: {
    showCount: {
      default: false,
      type: Boolean
    },
    showArrows: {
      default: true,
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
      containerWidth: 0,
      slideWidth: 0,
      slidesScope: {},
      nextSlideInterval: {},
      transitioning: false,
      transitionDuration: 600
    }
  },

  created() {
    window.onresize = () => {
      this.setSlideWidth()
      this.setSlideTransforms()
    }
  },

  mounted () {
    this.initData()
    this.initSlideInidices()
    this.initSlideOrders()
    this.setSlideWidth()
    this.setSlideTransforms()
    if (this.slideIntervalLength) { this.setSlideInterval() }
  },

  methods: {
    initData () {
      this.totalSlides = this.childSlideComponents.length / 3
      this.transitionDuration = getTransitionDuration(this.childSlideComponents[0].$el)
    },

    initSlideInidices () {
      this.childSlideComponents.forEach((child, index) => {
        child.index = index % this.totalSlides
      })
    },

    initSlideOrders () {
      this.childSlideComponents.forEach( (child, index) => {
        child.order = index
      })
    },

    setSlideWidth () {
      this.slideWidth = getWidthWithMargins(this.childSlideComponents[0].$el)
    },

    setSlideIntervalIfConfigured () {
      if (this.slideIntervalLength) {
        this.setSlideInterval()
      }
    },

    setSlideInterval () {
      this.nextSlideInterval = setInterval(() => {
        this.slideToNext(true)
      }, this.slideIntervalLength)
    },

    slideToNext (isAuto=false) {
      if (this.currentSlide === this.totalSlides) {
        this.changeSlide(1, isAuto)
      } else {
        this.changeSlide(this.currentSlide + 1, isAuto)
      }
    },

    slideToPrevious (isAuto=false) {
      if (this.currentSlide === 1) {
        this.changeSlide(this.totalSlides, isAuto)
      } else {
        this.changeSlide(this.currentSlide - 1, isAuto)
      }
    },

    changeSlide (slide, isAuto=false) {
      if (this.transitioning) { return }

      this.slideBy(getChangeInIndex(slide, this.currentSlide, this.totalSlides))
      this.currentSlide = slide

      if (!isAuto && this.slideIntervalLength) {
        this.resetSlideInterval()
      }
    },

    slideBy (changeInIndex) {
      this.shiftOrders(changeInIndex)
      this.setTransitioningTimeout()
      this.setSlideTransforms()
    },

    shiftOrders (changeInIndex) {
      this.childSlideComponents.forEach((child, index) => {
        child.order = getNewOrder(child.order, changeInIndex, this.totalSlides)
      })
    },

    setSlideTransforms () {
      this.childSlideComponents.forEach(child => {
        const newLeft = (child.order - this.totalSlides) * this.slideWidth

        if (newLeft * parseInt(child.$el.style.left) < 0) {
          this.brieflyRemoveSlideTransition(child.$el)
        }

        child.$el.style.left = newLeft + 'px'
      })
    },

    brieflyRemoveSlideTransition (el) {
      el.classList.remove('slide-transition')

      setTimeout(() => {
        el.classList.add('slide-transition')
      })
    },

    setTransitioningTimeout() {
      this.transitioning = true

      setTimeout(() => {  
        this.transitioning = false
      }, this.transitionDuration)
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
