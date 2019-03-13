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

  def hasParent? page
    page.parent
  end

  def breadcrumb_link page
    "<a href='/c#{page.full_path}' title='Visit #{page.label}' class='breadcrumbs__link'>#{page.label}</a>"
  end

  def get_breadcrumbs current_page
    page = current_page
    breadcrumbs = []

    breadcrumbs.push(breadcrumb_link(page))
    
    while hasParent?(page) && page.parent.label != 'Index'
      page = page.parent

      breadcrumbs.push(breadcrumb_link(page))
    end

    breadcrumbs
  end

  def get_filtered_pages pages
    if params[:year]
      pages = pages.where("date_part('year', created_at) = ?", params[:year])

      if params[:month]
        pages = pages.where("date_part('month', created_at) = ?", params[:month])
      end
    else
      pages
    end

    pages
  end
end
