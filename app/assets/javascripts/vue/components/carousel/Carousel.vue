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
    }
  },

  data() {
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
      transitionDuration: 600
    }
  },

  created() {
    window.onresize = () => {
      this.setSlideWidth()
      this.reorderSlides()
    }
  },

  mounted () {
    this.initData()
    this.initSlideOrders()
    this.setSlideWidth()
    this.initSlideContainerPosition()
    this.setSlideIntervalIfConfigured()
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
      this.slideContainer = this.$el.querySelector('#carousel-slides')
      this.transitionDuration = getTransitionDuration(this.slideContainer)
    },

    initSlideOrders () {
      this.childSlideComponents.forEach( (child, index) => {
        child.$el.style.order = index
      })
    },

    setSlideWidth () {
      this.slideWidth = getWidthWithMargins(this.childSlideComponents[0].$el)
    },

    initSlideContainerPosition () {
      this.slideContainer.style.left = - this.totalSlides * this.slideWidth + 'px'
    },

    setSlideIntervalIfConfigured () {
      if (this.slideIntervalLength) { this.setSlideInterval() }
    },

    setSlideInterval () {
      this.nextSlideInterval = setInterval(() => {
        this.slideToNext(true)
      }, this.slideIntervalLength)
    },

    resetSlideInterval () {
        clearInterval(this.nextSlideInterval)
        this.setSlideIntervalIfConfigured()
    },

    slideToNext (isAuto=false) {
      this.changeSlide(modGreaterThanZero(this.currentSlide + 1, this.totalSlides))
    },

    slideToPrevious (isAuto=false) {
      this.changeSlide(modGreaterThanZero(this.currentSlide - 1, this.totalSlides))
    },

    changeSlide (slide, isAuto=false) {
      if (this.transitioning) { return }
      
      if (!isAuto && this.slideIntervalLength) {
        this.resetSlideInterval()
      }

      this.slideBy(getChangeInIndex(slide, this.currentSlide, this.totalSlides))
      this.currentSlide = slide
    },

    slideBy (changeInIndex) {
      this.transitioning = true
      this.moveSlideContainer(changeInIndex)

      setTimeout(() => {
        this.invisiblyRepositionSlides(changeInIndex)

        //TODO: investigate using promises here
        setTimeout(() => { this.transitioning = false }, smallTimeout)
      }, this.transitionDuration)
    },

    moveSlideContainer (changeInIndex) {
      this.slideContainer.style.transform = `translateX(${- changeInIndex * this.slideWidth}px)`
    },

    invisiblyRepositionSlides(changeInIndex) {        
      this.reorderSlides(changeInIndex)
      this.resetSlideContainerPosition()
    },

    resetSlideContainerPosition () {
      this.brieflyRemoveTransition(this.slideContainer)
      this.slideContainer.style.transform = 'none'
    },

    brieflyRemoveTransition (el) {
      el.classList.remove('transition')

      setTimeout(() => {
        el.classList.add('transition')
      }, smallTimeout)
    },

    reorderSlides (changeInIndex) {
      this.childSlideComponents.forEach(child => {
        child.$el.style.order = getNewOrder(child.$el.style.order, changeInIndex, this.totalSlides)
      })
    }
  }
}
</script>
