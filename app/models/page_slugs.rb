# frozen_string_literal: true

# Single source of truth for CMS page slugs and other stable URL/path segments
# used in Ruby (routes, navigation, tests, presenters, etc.).
module PageSlugs
  # Top-level CMS pages (direct children of site index)
  ABOUT = 'about'
  NEWS_AND_STORIES = 'news-and-stories'
  RESOURCES = 'resources'
  MONTHLY_RELEASE_NEWS = 'monthly-release-news'
  LEGAL = 'legal'
  TERMS_AND_CONDITIONS = 'terms-and-conditions'

  # Call-to-action records (CallToAction#css_class)
  # Although it is called Class here but it is used as a slug/id for some reason
  module Cta
    API = 'api'
    # If you want to use protected-planet-report as a slug, you need to update the Slug in admin panel
    PROTECTED_PLANET_REPORT = 'live-report'
    MPA_GUIDE = 'mpa-guide'
  end

  # /data/* — CMS parent + children; some routes override with custom controllers
  module Data
    PARENT = 'data'

    WDPCA = 'wdpca'
    GDPAME = 'global-database-on-protected-area-management-effectiveness'

    def self.path(segment)
      "/#{PARENT}/#{segment}"
    end
  end

  # /thematic-areas/* — CMS parent + children; some routes override with custom controllers
  module ThematicAreas
    PARENT = 'thematic-areas'

    PROTECTED_AND_CONSERVED_AREAS = 'protected-and-conserved-areas'
    MARINE = 'marine-protected-areas'
    EFFECTIVENESS = 'protected-and-conserved-area-effectiveness'

    def self.path(slug)
      "/#{PARENT}/#{slug}"
    end
  end

  FOOTER_LINKS_PRIMARY = [RESOURCES, Data::WDPCA].freeze
  FOOTER_LINKS_SECONDARY = [ABOUT, LEGAL].freeze

  NAV_PRIMARY = [
    ABOUT,
    NEWS_AND_STORIES,
    RESOURCES,
    MONTHLY_RELEASE_NEWS,
    Data::PARENT,
    ThematicAreas::PARENT
  ].freeze
end
