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

  def cta_api
    @cta_api ||= CallToAction.find_by_css_class('api')
  end

  def cta_live_report
    @cta_live_report ||= CallToAction.find_by_css_class('live-report')
  end
end
