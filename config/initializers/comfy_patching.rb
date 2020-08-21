Rails.configuration.to_prepare do
  Comfy::Cms::Page.class_eval do
    has_many :pages_categories, foreign_key: 'page_id', dependent: :destroy
    has_many :page_categories, through: :pages_categories, foreign_key: 'page_id'

    has_many :topics, -> { joins(:layout_category).where("comfy_cms_layout_categories.label = 'topics'") },
      through: :pages_categories, class_name: 'Comfy::Cms::PageCategory', source: :page_category

    has_many :page_types, -> { joins(:layout_category).where("comfy_cms_layout_categories.label = 'types'") },
      through: :pages_categories, class_name: 'Comfy::Cms::PageCategory', source: :page_category

    accepts_nested_attributes_for :pages_categories
  end

  Comfy::Cms::Layout.class_eval do
    has_many :layouts_categories, foreign_key: 'layout_id', dependent: :destroy
    has_many :layout_categories, through: :layouts_categories, foreign_key: 'layout_id'

    accepts_nested_attributes_for :layouts_categories

    after_save :assign_layout_categories

    def assign_layout_categories
      _categories = self.content_tokens.select do |t|
        unless t.is_a?(Hash)
          false
        else
          t[:tag_class] == 'categories'
        end
      end

      delete_orphan_categories && return if _categories.blank?

      _categories.each do |cat|
        tag_name = cat[:tag_params].split(',').first
        _layout_category = Comfy::Cms::LayoutCategory.find_by(label: tag_name)
        Comfy::Cms::LayoutsCategory.find_or_create_by(
          layout_id: self.id,
          layout_category_id: _layout_category.id
        )
      end
    end

    def delete_orphan_categories
      layouts_categories = Comfy::Cms::LayoutsCategory.where(layout_id: self.id)

      self.pages.each do |page|
        layouts_categories.each do |lc|
          pcs_ids = page.page_categories.where(layout_category_id: lc.id).map(&:id)
          Comfy::Cms::PagesCategory.where(
            page_id: page.id,
            page_category_id: pcs_ids
          ).destroy_all
        end
      end

      layout_categories.destroy_all
    end
  end

  ComfortableMexicanSofa::Seeds::Page::Exporter.class_eval do
    def fragments_data(record, page_path)
      record.fragments.collect do |frag|
        header = "#{frag.tag} #{frag.identifier}"
        content =
          case frag.tag
          when "datetime", "date"
            frag.datetime
          when "checkbox"
            frag.boolean
          when "file", "files"
            frag.attachments.map do |attachment|
              ::File.open(::File.join(page_path, attachment.filename.to_s), "wb") do |f|
                f.write(attachment.download)
              end
              attachment.filename
            end.join("\n")
          # CUSTOM CODE - adding a case for categories to manually populate the content
          when "categories"
            layout_category = Comfy::Cms::LayoutCategory.where(label: frag.identifier).first
            record.page_categories.where(layout_category: layout_category).map do |category|
              category.label
            end.join(' ')
          # END OF CUSTOM CODE
          else
            frag.content
          end

        { header: header, content: content }
      end
    end

  end

  ComfortableMexicanSofa::Seeds::Page::Importer.class_eval do 
    def import_page(path, parent)
      slug = path.split("/").last

      # setting page record
      page =
        if parent.present?
          child = site.pages.where(slug: slug).first_or_initialize
          child.parent = parent
          child
        else
          site.pages.root || site.pages.new(slug: slug)
        end

      content_path = File.join(path, "content.html")

      # If file is newer than page record we'll process it
      if fresh_seed?(page, content_path)

        # reading file content in, resulting in a hash
        fragments_hash  = parse_file_content(content_path)

        # parsing attributes section
        attributes_yaml = fragments_hash.delete("attributes")
        attrs           = YAML.safe_load(attributes_yaml)

        # applying attributes
        layout = site.layouts.find_by(identifier: attrs.delete("layout")) || parent.try(:layout)
        category_ids    = category_names_to_ids(page, attrs.delete("categories"))
        target_page     = attrs.delete("target_page")

        page.attributes = attrs.merge(
          layout: layout,
          category_ids: category_ids
        )

        # applying fragments
        old_frag_identifiers = page.fragments.pluck(:identifier)

        new_frag_identifiers, fragments_attributes =
          construct_fragments_attributes(fragments_hash, page, path)

        
        # CUSTOM CODE
        # Destroy existing categories tied to page
        page.page_categories.destroy_all

        # Set the page categories 
        new_categories = []
        fragments_attributes.select { |attr| attr[:tag] == 'categories'}.each do |cat|
          cat[:content].split(' ').each do |label|
            category = Comfy::Cms::PageCategory.where(label: label).first
            new_categories << category unless category.nil?
          end
        end

        page.page_categories = new_categories unless new_categories.empty?
        # END OF CUSTOM CODE

        
        page.fragments_attributes = fragments_attributes

        if page.save
          message = "[CMS SEEDS] Imported Page \t #{page.full_path}"
          ComfortableMexicanSofa.logger.info(message)

          # defering target page linking
          if target_page.present?
            self.target_pages ||= {}
            self.target_pages[page.id] = target_page
          end

          # cleaning up old fragments
          page.fragments.where(identifier: old_frag_identifiers - new_frag_identifiers).destroy_all

        else
          message = "[CMS SEEDS] Failed to import Page \n#{page.errors.inspect}"
          ComfortableMexicanSofa.logger.warn(message)
        end
      end

      import_translations(path, page)

      # Tracking what page from seeds we're working with. So we can remove pages
      # that are no longer in seeds
      seed_ids << page.id

      # importing child pages (if there are any)
      Dir["#{path}*/"].each do |page_path|
        import_page(page_path, page)
      end
    end
  end

  # More Comfy patching, now patching the old Comfy CMS Helper
  Comfy::CmsHelper.module_eval do 
    def cms_fragment_content(identifier, page = @cms_page)
      frag = page&.fragments&.detect { |f| f.identifier == identifier.to_s }
      return "" unless frag
      case frag.tag
      when "date", "datetime", "date_not_null" # date_not_null is our own custom CMS tag
        frag.datetime
      when "checkbox"
        frag.boolean
      when "file", "files"
        frag.attachments
      else
        frag.content
      end
    end
  end
end