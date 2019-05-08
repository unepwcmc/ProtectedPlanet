<template>
  <div class="v-sticky-nav">
    <div class="v-sticky-nav__wrapper flex-row" :class="{ 'v-sticky-nav__wrapper--stuck' : this.isNavSticky, 'v-sticky-nav__wrapper--unstick' : !this.isNavSticky }">

      <p class="v-sticky-nav__title">Marine protected areas</p>

      <div 
        @click="toggleMenu" 
        class="burger v-sticky-nav__burger" 
        :class="{ 'burger--open' : isMenuOpen }">

        <span class="burger-icon v-sticky-nav__burger-icon"></span>
      </div>

      <ul class="v-sticky-nav__menu" :class="{ 'v-sticky-nav__menu--open' : this.isMenuOpen }">
        <li v-for="link in json" @click="closeMenu" class="v-sticky-nav__menu-item">
          <a :id="linkId(link.id)" class="v-sticky-nav__link" @click.prevent="scroll(link.id)">
            <span>{{ link.name }}</span>
          </a>
        </li>
      </ul>

    </div>
  </div>  
</template>

<script>
  export default {
    name: 'sticky-nav',

    props: {
      json: Array
    },

    data () {
      return {
        config: {
          breakpoints : {
            medium: 763 //this MUST match the breakpoint set in the responsive.scss file
          }
        },
        navClass: '.v-sticky-nav',
        navY: 0,
        navHeight: 0,
        isMenuOpen: false,
        isNavSticky: false
      }
    },

    mounted () {
      this.setNavHeight()
      this.navY = $(this.navClass).offset().top

      this.updateNav()
      this.monitorResize()

      // give d3 svgs a change to render before creating the scroll magic hooks
      window.setTimeout(() => {
        this.scrollMagicHandlers()
      }, 2000)
    },

    methods: {
      toggleMenu () {
        this.isMenuOpen = !this.isMenuOpen
      },

      closeMenu () {
        if(this.isMenuOpen){
          this.isMenuOpen = false
        }
      },

      updateNav () {
        setInterval(() => {
          const scrollY = window.pageYOffset
          
          if(scrollY > this.navY + this.navHeight){
            this.isNavSticky = true
          } else {
            this.isNavSticky = false
          }
        }, 100)
      },

      setNavHeight () {
        this.navHeight = $(this.navClass).height()
      },

      scroll: function (sectionId) {
        const sectionY = $('#' + sectionId).offset().top - this.navHeight + 1

        $('html, body').animate({
          scrollTop: sectionY
        }, 400, function(){
          window.location.hash = sectionId
        })
      },

      monitorResize () {
        $(window).on('resize', () => {
          width = $(window).width()

          if(width > this.config.breakpoints.medium){ this.isMenuOpen = false }

          this.setNavHeight()
          this.updateScrollMagicDurations()
        })
      },

      linkId (link) {
        return link + '-menu-item'
      },

      scrollMagicHandlers () {
        this.navScrollMagic = new ScrollMagic.Controller()

        let scrollMagicScenes = []

        // add scene for each item in the navigation
        this.json.forEach((link) => {
          let scene = {}
          
          scene.id = link.id

          scene.scene = new ScrollMagic.Scene({ 
            duration: this.getSceneDuration(link.id),
            triggerElement: '#' + link.id, 
            triggerHook: 'onLeave' 
          })
          .offset(-this.navHeight)
          .setClassToggle('#' + link.id + '-menu-item', 'v-sticky-nav__link-active')
          .addTo(this.navScrollMagic)

          scrollMagicScenes.push(scene)
        })

        this.scrollMagicScenes = scrollMagicScenes
      },

      updateScrollMagicDurations () {
        this.scrollMagicScenes.forEach((scene) => {
          scene.scene.duration(this.getSceneDuration(scene.id))
        })
      },

      getSceneDuration: function (id) {
        const section = $('#' + id)

        return section.innerHeight()
      }
    }
  }
</script>
