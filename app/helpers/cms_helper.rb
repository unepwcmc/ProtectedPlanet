module CmsHelper
  def article_version_element version
    ["vertical-nav__element"].tap { |classes|
      classes << "vertical-nav__element--selected" if version == @cms_page
    }.join(' ')
  end
end
