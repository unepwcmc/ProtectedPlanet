require 'test_helper'
require 'tmpdir'

# Guards the CMS seed export -> import pipeline (comfy_patching.rb) on Ruby 3.
# Regression coverage for bugs the manual round-trip found during the Media Surfer
# port: Psych safe_load rejecting datetime attrs (TimeWithZone), and nil crashes
# on empty file/category fragments. Previously zero coverage — only factories.
class CmsSeedRoundtripTest < ActiveSupport::TestCase
  test 'page seed export and re-import round-trips with datetime and empty fragments' do
    Dir.mktmpdir do |dir|
      original_path = ComfortableMediaSurfer.config.seeds_path
      ComfortableMediaSurfer.config.seeds_path = dir
      begin
        Comfy::Cms::Site.where(identifier: 'seedtest').destroy_all
        site   = Comfy::Cms::Site.create!(identifier: 'seedtest', label: 'seedtest', hostname: 'seedtest.example')
        layout = site.layouts.create!(identifier: 'default', label: 'default', content: '{{cms:wysiwyg content}}')
        page   = site.pages.create!(slug: 'index', label: 'Home', layout: layout) # root page
        # datetime -> TimeWithZone in the exported YAML (safe_load must permit it)
        page.fragments.create!(identifier: 'published_date', tag: 'date_not_null',
                               datetime: Time.zone.local(2020, 1, 1))
        # empty category + file fragments (import must not nil-crash)
        page.fragments.create!(identifier: 'topics', tag: 'categories', content: nil)
        page.fragments.create!(identifier: 'hero_image', tag: 'file')

        ComfortableMediaSurfer::Seeds::Page::Exporter.new(site.identifier).export!
        assert Dir.glob(File.join(dir, site.identifier, 'pages', '**', 'content.html')).any?,
               'expected an exported content.html'

        # Destroy so the re-import exercises the full create path (fresh_seed?).
        page.destroy!
        assert_not Comfy::Cms::Page.exists?(slug: 'index', site_id: site.id)

        assert_nothing_raised do
          ComfortableMediaSurfer::Seeds::Page::Importer.new(site.identifier).import!
        end

        reimported = Comfy::Cms::Page.find_by(slug: 'index', site_id: site.id)
        assert reimported, 'page should be recreated from the seed'
        assert_equal Date.new(2020, 1, 1),
                     reimported.fragments.find_by(identifier: 'published_date').datetime.to_date
      ensure
        ComfortableMediaSurfer.config.seeds_path = original_path
      end
    end
  end
end
