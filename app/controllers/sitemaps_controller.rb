# frozen_string_literal: true

# See lib/modules/sitemap.rb.
class SitemapsController < ApplicationController
  # load_cms_content runs a Comfy lookup that can only miss for these paths.
  skip_before_action :load_cms_site
  skip_before_action :load_cms_content
  skip_before_action :check_for_pdf

  # The one place that still asks a shared cache to hold a response. Safe here and
  # not for HTML: the TTL is sized to a release, and a sitemap that is a few hours
  # behind costs nothing, where a CMS page that is costs an editor their afternoon.
  after_action :cache_for_sitemap_ttl

  def index
    render_sitemap Sitemap.index_xml(sitemap_base_url)
  end

  def show
    name = params[:name].to_s

    return head :not_found unless Sitemap.valid_chunk_name?(name)

    render_sitemap Sitemap.chunk_xml(name, sitemap_base_url)
  end

  private

  # force_ssl is commented out in production.rb, so a request arriving without
  # X-Forwarded-Proto would publish a sitemap of http URLs that all 301 -- which
  # Google discards. Local envs keep whatever scheme they are served over.
  def sitemap_base_url
    base_url = request.base_url
    return base_url if request.ssl? || Rails.env.local?

    base_url.sub(/\Ahttp:/, 'https:')
  end

  def render_sitemap(xml)
    render xml: xml, content_type: 'application/xml'
  end

  def cache_for_sitemap_ttl
    expires_in Sitemap::CACHE_TTL, public: true
  end
end
