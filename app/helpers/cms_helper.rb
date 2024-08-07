module CmsHelper
  PARAGRAPH_SELECTOR = 'p'
  def article_version_element version
    ["vertical-nav__element"].tap { |classes|
      classes << "vertical-nav__element--selected" if version == @cms_page
    }.join(' ')
  end

  NO_PREVIEW_MSG = "No preview available"
  def search_result_preview resource
    content = Nokogiri::HTML(resource.content_cache)
    first_paragraph = content.css(PARAGRAPH_SELECTOR).detect { |p| p.content.length > 10 }

    if first_paragraph
      content_tag(:p, first_paragraph.content.truncate(250), class: 'search-result__body')
    else
      content_tag(:em, NO_PREVIEW_MSG, class: 'search-result__body') if first_paragraph.nil?
    end
  end

  def cms_page page, current_page
    el = 'vertical-nav__element'
    modifiers = [].tap { |m|
      if current_page == page
        m << 'active'
        m << 'selected'
      end
    }

    link_to(page.label, cms_page_path(page), class: bem(el, *modifiers))
  end

  def cms_page_path page
    File.join('/c/', page.site.path, page.full_path)
  rescue
    "#"
  end

  def get_category_filters
    category_groups = load_categories 

    [
      {
        title: I18n.t('search.filter-by'),
        filters: category_groups.map do |group|
          {
            id: group[:id],
            options: group[:items],
            title: group[:title],
            type: 'checkbox'
          }
        end
      }
    ].to_json
  end

  def get_cms_tabs total_tabs
    tabs = []

    total_tabs.times do |i|
      tab = {
        id: i+1,
        title: @cms_page.fragments.where(identifier: "tab-title-#{i+1}").first.content
      }

      tabs << tab
    end

    tabs
  end

  def hasParent? page
    page.parent
  end

  def breadcrumb_link page
    "<a href='/c#{page.full_path}' title='Visit #{page.label}' class='breadcrumbs__link'>#{page.label}</a>"
  end

  def get_breadcrumbs current_page
    page = current_page
    breadcrumbs = []

    breadcrumbs << breadcrumb_link(page)

    while hasParent?(page) && page.parent.label != 'Index'
      page = page.parent

      breadcrumbs << breadcrumb_link(page)
    end

    breadcrumbs
  end

  def get_filtered_pages pages
    if params[:year]
      pages = pages.select{|page| page['created_at'].year == params[:year].to_i}

      if params[:month]
        pages = pages.select{|page| page['created_at'].month == params[:month].to_i}
      end
    else
      pages
    end

    pages
  end

  def load_categories
    return [] unless @cms_page
    layouts_categories = Comfy::Cms::LayoutsCategory.where(layout_id: @cms_page.layout_id)

    # TODO This is a workaround to load the custom categories also based on child pages
    # in case the categories for the given page are empty.
    # This seems to be necessary now because the layout used for the main page
    # can be different from the layout used in the child pages
    if layouts_categories.blank?
      children_layouts = @cms_page.children.map(&:layout_id)
      layouts_categories = Comfy::Cms::LayoutsCategory.where(layout_id: children_layouts)
        .map(&:layout_category).uniq
    end

    categories_yml = I18n.t('search')[:custom_categories]

    layouts_categories.map do |lc|

      title = categories_yml[lc.label.to_sym][:name]
      name = title.downcase
      page_categories = lc.page_categories
      localised_pcs = categories_yml[name.to_sym][:items]

      items = page_categories.map do |pc|
        {
          id: pc.id,
          title: localised_pcs[pc.label.to_sym]
        }
      end

      # frontend should return the list of selected categories as follows:
      # 'group_name' => [category_ids] ; e.g. 'topics' => [1,2,3]
      {
        id: name,
        items: items,
        title: title
      }
    end
  end

  def cta_api
    @cta_api ||= CallToAction.find_by_css_class('api')
  end

  def cta_live_report
    @cta_live_report ||= CallToAction.find_by_css_class('live-report')
  end

  def cta_mpa 
    @cta_mpa ||= CallToAction.find_by_css_class('mpa-guide')
  end

  def get_resource_links 
    [
      get_resource(:resource_link_text, :resource_link_url, 'link', 'link-external'),
      get_resource(:resource_file_title, :resource_file, 'download', 'download')
    ].compact
  end

  private

  #  variation of resource link, if it is just a link, or whether it is a file
  # if those specific fragments for that page are present
  def get_resource(fragment_text, fragment_link, button_text, button_class)
    frag_text = @cms_page.fragments.find_by(identifier: fragment_text)
    frag_link = @cms_page.fragments.find_by(identifier: fragment_link)
    return unless frag_text || frag_link

    {
      button: I18n.t("global.button.#{button_text}"),
      classes: "button--#{button_class}",
      text: cms_fragment_render(fragment_text, @cms_page),
      title: cms_fragment_render(fragment_text, @cms_page),
      url: transform_into_url(frag_link)
    }
  end

  # Turns link[:url] value into a valid link if no http:// or https:// supplied
  # Also sanitises it in the case of a download link
  def transform_into_url(fragment_link)
    if fragment_link.tag == 'file'
      return if !fragment_link.attachments || fragment_link.attachments.first.blank?
      if Rails.env.development?
        return rails_blob_path(fragment_link.attachments.first)
      else
        return fragment_link.attachments.first.service_url&.split('?')&.first
      end
    else
      fragment_link.content
    end
  end

  def cms_fragment_content_datetime(identifier, page)
    # Might not be able to find that particular tag and identifier combo -  hence the try
    date = page.fragments.find_by(tag: 'date_not_null', identifier: identifier).try(:datetime)
    date ? date : cms_fragment_content(identifier, page)
  end
end
