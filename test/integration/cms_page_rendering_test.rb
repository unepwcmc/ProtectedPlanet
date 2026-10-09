require 'test_helper'

# Nothing else in the suite drives a CMS page through Comfy::Cms::ContentController at
# all, so a change to the Comfy patches in config/initializers/comfy_patching.rb could
# break every /en/about, /en/news and /en/resources page with the suite still green.
# This is the net under that.
class CmsPageRenderingTest < ActionDispatch::IntegrationTest
  BODY = 'Marine protected areas cover a growing share of the ocean.'.freeze

  def setup
    @site = Comfy::Cms::Site.create!(
      label: 'test', identifier: 'test', hostname: 'www.example.com', path: '/', locale: 'en'
    )
    @layout = @site.layouts.create!(
      label: 'plain', identifier: 'plain', content: %(<div id="layout-v1">{{ cms:wysiwyg body }}</div>)
    )
    # The first parentless page becomes the site root at '/', whatever its slug, so the
    # page under test has to be its child to live at /about. And /about without the
    # locale is not this page: `get '/:id'` (protected areas) is declared first.
    @root = @site.pages.create!(
      label: 'Home', slug: '', layout: @layout, is_published: true,
      fragments_attributes: [{ identifier: 'body', tag: 'wysiwyg', content: 'Home.' }]
    )
    @page = @site.pages.create!(
      label: 'About', slug: 'about', parent: @root, layout: @layout, is_published: true,
      fragments_attributes: [{ identifier: 'body', tag: 'wysiwyg', content: BODY }]
    )
  end

  test 'a CMS page renders its content inside its layout' do
    get '/en/about'

    assert_response :success
    assert_includes response.body, BODY
    assert_includes response.body, 'id="layout-v1"'
  end

  test 'the markup is not escaped' do
    get '/en/about'

    assert_not_includes response.body, '&lt;div'
  end

  test 'the content type is text/html' do
    get '/en/about'

    assert_equal 'text/html', response.media_type
  end

  # Nothing stands between an editor's save and the page -- see docs/caching.md.
  test 'an edit through the admin path is live on the next request' do
    get '/en/about'
    assert_includes response.body, BODY

    # reload mirrors the admin, which loads the page fresh. Without it this instance
    # still holds the nil content_cache it was created with, so Comfy's
    # `before_save :clear_content_cache` changes nothing, the record is not dirty, and
    # no UPDATE runs -- the row keeps its old content_cache.
    @page.reload.update!(fragments_attributes: [
      { identifier: 'body', tag: 'wysiwyg', content: 'Rewritten.' }
    ])

    get '/en/about'

    assert_includes response.body, 'Rewritten.'
    assert_not_includes response.body, BODY
  end

  test 'a layout edit is live on the next request' do
    get '/en/about'
    assert_includes response.body, 'id="layout-v1"'

    # reload for the same reason, plus one of its own: Comfy's
    # `after_save :clear_page_content_cache` nulls `pages.pluck(:id)`, and this instance
    # predates the pages, so its association is cached empty and the clear would
    # silently reach nothing.
    @layout.reload.update!(content: %(<div id="layout-v2">{{ cms:wysiwyg body }}</div>))

    get '/en/about'

    assert_includes response.body, 'id="layout-v2"'
    assert_not_includes response.body, 'id="layout-v1"'
  end

  test 'a missing page is a 404' do
    get '/en/no-such-page'

    assert_response :not_found
  end
end
