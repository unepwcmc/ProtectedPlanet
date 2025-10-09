<template>
  <div v-if="visible" class="banner" :class="bannerClass" :data-banner-sig="signature">
    <div class="banner__container container">
      <!-- Single banner -->
      <div v-if="banners.length === 1" class="banner__content">
        <h3 v-if="banners[0].title" class="banner__title">{{ banners[0].title }}</h3>
        <div class="banner__body" v-html="banners[0].content"></div>
      </div>
      
      <!-- Multiple banners with navigation -->
      <template v-else>
        <button 
          class="banner__nav banner__nav--prev" 
          @click="previousBanner"
          aria-label="Previous banner" 
          title="Previous"
        >
          &#10094;
        </button>
        
        <div class="banner__slides">
          <div 
            v-for="(banner, index) in banners" 
            :key="banner.id"
            :class="['banner__slide', { 'is-active': index === currentIndex }]"
            :data-banner-id="banner.id"
          >
            <div class="banner__content">
              <h3 v-if="banner.title" class="banner__title">{{ banner.title }}</h3>
              <div class="banner__body" v-html="banner.content"></div>
            </div>
          </div>
        </div>
        
        <button 
          class="banner__nav banner__nav--next" 
          @click="nextBanner"
          aria-label="Next banner" 
          title="Next"
        >
          &#10095;
        </button>
      </template>
      
      <button 
        class="banner__close" 
        @click="closeBanner"
        aria-label="Close banner"
      >
        <span aria-hidden="true">&times;</span>
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Banner',
  
  props: {
    banners: {
      type: Array,
      default: () => []
    },
    signature: {
      type: String,
      default: ''
    }
  },
  
  data() {
    return {
      currentIndex: 0,
      visible: true
    }
  },
  
  mounted() {
    console.log('Banner component mounted with banners:', this.banners)
  },
  
  computed: {
    bannerClass() {
      if (this.banners.length === 1) {
        return ''
      }
      return 'banner--carousel'
    }
  },
  
  methods: {
    nextBanner() {
      this.currentIndex = (this.currentIndex + 1) % this.banners.length
    },
    
    previousBanner() {
      this.currentIndex = (this.currentIndex - 1 + this.banners.length) % this.banners.length
    },
    
    closeBanner() {
      // Set cookie based on single vs multiple banners
      if (this.banners.length === 1) {
        this.setCookie('banner_closed', this.banners[0].id.toString())
      } else {
        this.setCookie('banner_closed_sig', this.signature)
      }
      
      // Hide with animation
      this.visible = false
    },
    
    setCookie(name, value) {
      document.cookie = `${name}=${value}; path=/; max-age=1209600` // 2 weeks
    }
  }
}
</script>
