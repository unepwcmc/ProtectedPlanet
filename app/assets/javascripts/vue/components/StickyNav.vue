<template>
  <div class="v-sticky-nav">
    <div class="v-sticky-nav__wrapper flex-row" :class="{ 'v-sticky-nav__wrapper--stuck' : this.isNavSticky, 'v-sticky-nav__wrapper--unstick' : !this.isNavSticky }">

      <p class="v-sticky-nav__title">Marine protected areas</p>

      <div 
        @click="toggleMenu" 
        class="v-sticky-nav__burger" 
        :class="{ 'v-sticky-nav__burger--open' : isMenuOpen }">

        <span class="v-sticky-nav__burger-icon"></span>
      </div>

      <ul class="v-sticky-nav__menu" :class="{ 'v-sticky-nav__menu--open' : this.isMenuOpen }">
        <li v-for="link in json" @click="closeMenu" class="v-sticky-nav__menu-item">
          <a :id="linkId(link.id)" class="v-sticky-nav__link" @click.prevent="scroll(link.id)">{{ link.name }}</a>
        </li>
      </ul>

    </div>
  </div>  
</template>

<script>
  module.exports = {
    name: 'sticky-nav',

    props: {
      json: Array
    },

    data: function() {
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

    mounted: function() {
      this.setNavHeight()
      this.navY = $(this.navClass).offset().top

      this.updateNav()
      this.monitorResize()

      // give d3 svgs a change to render before creating the scroll magic hooks
      var self = this

      window.setTimeout(function () {
        self.scrollMagicHandlers()
      }, 2000)
    },

    methods: {
      toggleMenu: function () {
        this.isMenuOpen = !this.isMenuOpen
      },

      closeMenu: function () {
        if(this.isMenuOpen){
          this.isMenuOpen = false
        }
      },

      updateNav: function () {
        var self = this

        setInterval(function () {
          scrollY = window.pageYOffset
          
          if(scrollY > self.navY + self.navHeight){
            self.isNavSticky = true
          } else {
            self.isNavSticky = false
          }
        }, 100)
      },

      setNavHeight: function () {
        this.navHeight = $(this.navClass).height()
      },

      scroll: function (sectionId) {
        sectionY = $('#' + sectionId).offset().top - this.navHeight + 1

        $('html, body').animate({
          scrollTop: sectionY
        }, 400, function(){
          window.location.hash = sectionId
        })
      },

      monitorResize: function () {
        var self = this

        $(window).on('resize', function(){
          width = $(window).width()

          if(width > self.config.breakpoints.medium){ self.isMenuOpen = false }

          self.setNavHeight()
          self.updateScrollMagicDurations()
        })
      },

      linkId: function (link) {
        return link + '-menu-item'
      },

      scrollMagicHandlers: function () {
        this.navScrollMagic = new ScrollMagic.Controller()

        var self = this
        var scrollMagicScenes = []

        // add scene for each item in the navigation
        this.json.forEach(function (link) {
          var scene = {}
          
          scene.id = link.id

          scene.scene = new ScrollMagic.Scene({ 
            duration: self.getSceneDuration(link.id),
            triggerElement: '#' + link.id, 
            triggerHook: 'onLeave' 
          })
          .offset(-self.navHeight)
          .setClassToggle('#' + link.id + '-menu-item', 'v-sticky-nav__link-active')
          .addTo(self.navScrollMagic)

          scrollMagicScenes.push(scene)
        })

        this.scrollMagicScenes = scrollMagicScenes
      },

      updateScrollMagicDurations: function () {
        var self = this

        this.scrollMagicScenes.forEach(function (scene) {
          scene.scene.duration(self.getSceneDuration(scene.id))
        })
      },

      getSceneDuration: function (id) {
        var section = $('#' + id)

        return section.innerHeight()
      }
    }
  }
</script>
