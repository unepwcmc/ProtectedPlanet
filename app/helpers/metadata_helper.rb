module MetadataHelper
  def site_title
    t('seo.defaults.site_title')
  end

  def site_description
    t('seo.defaults.site_description')
  end

  def page_title
    custom_title = content_for(:page_title)

    if custom_title
      "#{custom_title} | #{site_title}".html_safe
    else
      site_title
    end
  end

  def social_image
    if content_for?(:social_image)
      content_for(:social_image)
    elsif t("#{translation_path}.social_image")
      t("#{translation_path}.social_image")
    else
      URI.join(root_url, image_path('social.png'))
    end
  end

  def social_image_alt
    if content_for?(:social_image_alt)
      content_for(:social_image_alt)
    else
      t("#{translation_path}.social_image_alt", default: t('opengraph.defaults.image_alt'))
    end
  end

  def seo_description
    if content_for?(:seo)
      content_for(:seo)
    else
      t('seo.defaults.description')
    end
  end

  def twitter_card
    if content_for?(:twitter_card)
      content_for(:twitter_card)
    else
      t("#{translation_path}.social_twitter_card", default: 'summary')
    end
  end

  def social_title
    if content_for?(:social_title)
      sanitize content_for(:social_title)
    else
      t("#{translation_path}.title", default: page_title('Protected Planet'))
    end
  end

  def social_description
    if content_for?(:social_description)
      sanitize content_for(:social_description)
    else
      t("#{translation_path}.social_description", default: seo_description)
    end
  end

  private

  def translation_path
    case controller_name
    when 'target_dashboard'
      'thematic_area.target_11_dashboard'
    else
      controller_name
    end
  end
end
