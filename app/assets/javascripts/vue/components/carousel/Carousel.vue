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
        <slot></slot>
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
//TODO: permenant title offscreen for accessibility?
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

  created() {
    window.onresize = () => {
      this.setSlideWidth()
      this.setSlideTransform()
    }
  },

  mounted () {
    this.totalSlides = this.children.length
    this.addIndices()
    this.setSlideWidth()
    this.setSlideInterval()
    this.slidesEl = this.$el.querySelector('#carousel-slides')
  },

  methods: {
    addIndices () {
      this.children.forEach( (child, index) => {
        child.index = index
      })
    },

    setSlideWidth () {
      this.slideWidth = this.getWidthWithMargins(this.children[0].$el)
    },

    //TODO: export to helper
    getWidthWithMargins (element) {
      const style = element.currentStyle || window.getComputedStyle(element)
      
      return element.offsetWidth + parseInt(style.marginLeft, 10) + parseInt(style.marginRight, 10)
    },

    setSlideInterval () {
      this.nextSlideInterval = setInterval(() => {
        this.setNextSlide(true)
      }, 4000)
    },

    setNextSlide (isAuto=false) {
      if (this.currentSlide === this.totalSlides) {
        this.changeSlide(1, isAuto)
      } else {
        this.changeSlide(this.currentSlide + 1, isAuto)
      }
    },

    changeSlide (slide, isAuto=false) {
      this.currentSlide = slide
      this.setSlideTransform()

      if (!isAuto) {
        this.resetSlideInterval()
      }
    },

    setSlideTransform () {
      const shift = (this.currentSlide - 1) * this.slideWidth

      this.slidesEl.style.transform = `translateX(-${shift}px)`
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
    }
  }
}
</script>
