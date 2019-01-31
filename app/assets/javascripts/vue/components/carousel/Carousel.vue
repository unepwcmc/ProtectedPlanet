<template>
  <aside class="carousel" aria-labelledby="carousel-heading">

    <h1 id="carousel-heading" :class="{'screen-reader': !showTitle}">{{ title }}</h1>

    <h2 :class="{'screen-reader': !showSlideCount}">{{ currentSlide }} of {{ totalSlides }}</h2>

    <div class="carousel__slides-container">

      <ul id="carousel-slides" class="carousel__slides transition" aria-live="off" aria-atomic="true">
        <template v-for="n in 3">
          <slot :slidesScope="slidesScope"></slot>
        </template>
      </ul>

      <div v-if="showArrows && hasMutlipleSlides" class="carousel__arrow-buttons">
        <button aria-controls="carousel-slides" title="Previous slide" class="carousel__arrow carousel__arrow--left" @click="slideToPrevious()">
          <span class="fas fa-chevron-left"></span>
        </button>
        <button aria-controls="carousel-slides" title="Next slide" class="carousel__arrow carousel__arrow--right" @click="slideToNext()">
          <span class="fas fa-chevron-right"></span>
        </button>
      </div>

    </div>

    <div v-if="hasMutlipleSlides" class="carousel__control-bar">
      <template v-if="showIndicators">
        <button
          v-for="slide in totalSlides"
          :title="indicatorTitle(slide)"
          aria-controls="carousel-slides"
          :aria-pressed="isCurrentSlide(slide)"
          :class="['carousel__indicator', selectedSlideClass(slide)]"
          @click="changeSlide(slide)"></button>
      </template>

      <button :title="pauseTitle" v-if="slideIntervalLength" class="carousel__pause" @click="toggleSlideInterval">
        <span :class="[pauseIconClass]"></span>
      </button>
    </div>

  </aside>
</template>

<script>
const smallTimeout = 20

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
    },
    showAllIndicators: {
      default: false,
      type: Boolean
    }
  },

  data: function () {
    return {
      currentSlide: 1,
      totalSlides: 0,
      childSlideComponents: this.$children,
      slideContainer: {},
      containerWidth: 0,
      slideWidth: 0,
      slidesScope: {},
      nextSlideInterval: {},
      transitioning: false,
      transitionendHandler: {},
      isPaused: Boolean(this.slideIntervalLength)
    }
  },

  created: function() {
    window.onresize = function () {
      this.setSlideWidth()
      this.initSlideContainerPosition()
    }.bind(this)
  },

  mounted: function () {
    this.initData()
    this.initSlideOrders()
    this.setSlideWidth()
    this.initSlideContainerPosition()
    this.setActiveStateOnChildren()
    this.setSlideIntervalIfConfigured()
  },

  computed: {
    hasMutlipleSlides: function () {
      return this.childSlideComponents.length > 3
    },

    showSlideCount: function () {
      return this.showCount && this.hasMutlipleSlides
    },

    pauseIconClass: function () {
      return this.isPaused ? 'fas fa-play': 'fas fa-pause'
    },

    pauseTitle: function () {
      return this.isPaused ? 'Resume carousel' : 'Pause carousel'
    },

    showIndicators: function () {
      return this.showAllIndicators || this.totalSlides < 7
    }
  },

  methods: {
    selectedSlideClass: function (slide) {
      return {'carousel__indicator--selected' : this.isCurrentSlide(slide)}
    },

    isCurrentSlide: function (slide) {
      return slide === this.currentSlide
    },

    isCurrentSlideElement: function (slideElement) {
      return slideElement.style.order == this.totalSlides
    },

    indicatorTitle: function (slide) {
      return 'Move to slide ' + slide
    },

    initData: function () {
      this.totalSlides = this.childSlideComponents.length / 3
      this.slideContainer = this.$el.querySelector('#carousel-slides')
    },

    initSlideOrders: function () {
      Array.prototype.forEach.call(this.childSlideComponents, function (child, index) {
        child.$el.style.order = index
      })
    },

    setSlideWidth: function () {
      this.slideWidth = getWidthWithMargins(this.childSlideComponents[0].$el)
    },

    initSlideContainerPosition: function () {
      this.slideContainer.style.left = - this.totalSlides * this.slideWidth + 'px'
    },

    resetSlideIntervalIfNotPaused: function () {
      if (!this.isPaused) {
        this.clearSlideInterval()
        this.setSlideIntervalIfConfigured()
      }
    },

    toggleSlideInterval: function () {
      this.isPaused ? this.setSlideIntervalIfConfigured() : this.clearSlideInterval()
    },

    setSlideIntervalIfConfigured: function () {
      if (this.slideIntervalLength) { this.setSlideInterval() }
    },

    setSlideInterval: function () {
      this.nextSlideInterval = setInterval(function () {
        this.slideToNext(false)
      }.bind(this), this.slideIntervalLength)

      this.isPaused = false
    },

    clearSlideInterval: function () {
      clearInterval(this.nextSlideInterval)
      this.isPaused = true
    },

    slideToNext: function (resetNextSlideInterval) {
      if(resetNextSlideInterval === undefined) {resetNextSlideInterval = true}

      this.changeSlide(modGreaterThanZero(this.currentSlide + 1, this.totalSlides), resetNextSlideInterval, 1)
    },

    slideToPrevious: function (resetNextSlideInterval) {
      if(resetNextSlideInterval === undefined) {resetNextSlideInterval = true}

      this.changeSlide(modGreaterThanZero(this.currentSlide - 1, this.totalSlides), resetNextSlideInterval, -1)
    },

    changeSlide: function (slide, resetNextSlideInterval, forceDirection) {
      if(resetNextSlideInterval === undefined) {resetNextSlideInterval = true}
      if(forceDirection === undefined) {forceDirection = 0}

      if (this.transitioning || slide === this.currentSlide) { return }
      
      if (resetNextSlideInterval) { this.resetSlideIntervalIfNotPaused() }

      this.slideBy(getChangeInIndex(slide, this.currentSlide, this.totalSlides, forceDirection))
      this.currentSlide = slide
    },

    slideBy: function (changeInIndex) {
      this.transitioning = true
      this.moveSlideContainer(changeInIndex)
      this.replaceTransitionendHandler(changeInIndex)
    },

    moveSlideContainer: function (changeInIndex) {
      this.slideContainer.style.transform = 'translateX('+ (- changeInIndex * this.slideWidth) + 'px)'
    },
    
    replaceTransitionendHandler: function (changeInIndex) {
      this.slideContainer.removeEventListener('transitionend', this.transitionendHandler)
      this.transitionendHandler = this.getOnTransitionEndHandler(changeInIndex)
      this.slideContainer.addEventListener('transitionend', this.transitionendHandler)
    },

    getOnTransitionEndHandler: function (changeInIndex) {
      return function () {
        this.invisiblyRepositionSlides(changeInIndex)
        this.setActiveStateOnChildren()
  
        setTimeout(function () { this.transitioning = false }.bind(this), smallTimeout)
      }.bind(this)
    },

    invisiblyRepositionSlides: function (changeInIndex) {        
      this.reorderSlides(changeInIndex)
      this.resetSlideContainerPosition()
    },

    resetSlideContainerPosition: function () {
      this.brieflyRemoveTransition(this.slideContainer)
      this.slideContainer.style.transform = 'none'
    },

    brieflyRemoveTransition: function (el) {
      el.classList.remove('transition')

      setTimeout(function () {
        el.classList.add('transition')
      }, smallTimeout)
    },

    reorderSlides: function (changeInIndex) {
      Array.prototype.forEach.call(this.childSlideComponents, function (child) {
        child.$el.style.order = getNewOrder(child.$el.style.order, changeInIndex, this.totalSlides)
      }.bind(this))
    },

    setActiveStateOnChildren: function () {
      Array.prototype.forEach.call(this.childSlideComponents, function (child) {
        child.isActive = this.isCurrentSlideElement(child.$el)
      }.bind(this))
    }
  }
}
</script>
