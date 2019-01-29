<template>
  <aside class="carousel" aria-labelledby="carousel-heading">

    <h1 id="carousel-heading" :class="{'screen-reader': !showTitle}">{{ title }}</h1>

    <h2 :class="{'screen-reader': !showSlideCount}">{{ currentSlide }} of {{ totalSlides }}</h2>

    <div class="carousel__slides-container">

      <ul id="carousel-slides" class="carousel__slides" aria-live="off" aria-atomic="true">
        <template v-for="n in 3">
          <slot :slidesScope="slidesScope"></slot>
        </template>
      </ul>

      <div v-if="showArrows && hasMutlipleSlides" class="carousel__arrow-buttons">
        <button aria-controls="carousel-slides" title="Next slide" class="carousel__arrow carousel__arrow--left" @click="slideToPrevious()">
          <span class="fas fa-chevron-left"></span>
        </button>
        <button aria-controls="carousel-slides" title="Previous slide" class="carousel__arrow carousel__arrow--right" @click="slideToNext()">
          <span class="fas fa-chevron-right"></span>
        </button>
      </div>

    </div>

    <div v-if="hasMutlipleSlides" class="carousel__indicators">
      <button
        v-for="slide in totalSlides"
        :title="`Move to slide ${slide}`"
        aria-controls="carousel-slides"
        :aria-pressed="isCurrentSlide(slide)"
        :class="['carousel__indicator', selectedSlideClass(slide)]"
        @click="changeSlide(slide)"></button>
    </div>

  </aside>
</template>

<script>
//TODO: permenant title offscreen for accessibility?
module.exports = {
  name: 'carousel',

  props: {
    title: {
      default: 'Carousel',
      type: String
    },
    showTitle: {
      default: false,
      type: Boolean
    },
    showArrows: {
      default: true,
      type: Boolean
    },
    showCount: {
      default: false,
      type: Boolean
    },
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

  computed: {
    hasMutlipleSlides () {
      return this.childSlideComponents.length > 3
    },

    showSlideCount () {
      return this.showCount && this.hasMutlipleSlides
    }
  },

  methods: {
    selectedSlideClass (slide) {
      return {'carousel__indicator--selected' : this.isCurrentSlide(slide)}
    },

    isCurrentSlide (slide) {
      return slide === this.currentSlide
    },

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
      if (this.slideIntervalLength) { this.setSlideInterval() }
    },

    setSlideInterval () {
      this.nextSlideInterval = setInterval(() => {
        this.slideToNext(true)
      }, this.slideIntervalLength)
    },

    slideToNext (isAuto=false) {
      this.changeSlide(modGreaterThanZero(this.currentSlide + 1, this.totalSlides))
    },

    slideToPrevious (isAuto=false) {
      this.changeSlide(modGreaterThanZero(this.currentSlide - 1, this.totalSlides))
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
    }
  }
}
</script>
