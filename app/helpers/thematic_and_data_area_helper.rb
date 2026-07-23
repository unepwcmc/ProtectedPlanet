# frozen_string_literal: true

module ThematicAndDataAreaHelper
  MAX_TABS = 5

  def thematic_and_data_area_tabs(page = @cms_page)
    (1..MAX_TABS).map do |tab_id|
      content_id = "tab-content-#{tab_id}"
      title = cms_fragment_content(:"tab-title-#{tab_id}", page)
      content = cms_fragment_content(content_id, page)
      next if title.blank? && content.blank?

      {
        id: tab_id,
        title: title,
        content_id: content_id
      }
    end.compact
  end

  def thematic_and_data_area_show_tab_triggers?(tabs_list)
    tabs_list.count { |tab| tab[:title].present? } > 1
  end

  # Props for `frontend_mount "Tabs"` — only valid when no tab has `tab_extras`
  # (those embed legacy Vue2 widgets still bound to `#v-app`, see
  # ThematicAndDataAreaHelper#thematic_and_data_area_tab_extras_config).
  def thematic_and_data_area_vue_tabs(tabs_list)
    tabs_list.map do |tab|
      {
        id: tab[:id],
        title: tab[:title],
        bodyHtml: content_tag(:section, cms_fragment_render(tab[:content_id]), class: "container--medium")
      }
    end
  end

  def thematic_and_data_area_tab_extras_config(tab, tab_extras)
    return if tab_extras.blank?

    Array(tab_extras).find { |extra| extra[:tab_id].to_i == tab[:id].to_i }
  end

  def thematic_and_data_area_hero_locals(page = @cms_page)
    locals = {
      classes: "#{page.slug} thematic-area",
      image: cms_fragment_render(:image, page),
      summary: cms_fragment_render('summary', page),
      title: page.fragments.find_by(identifier: 'short_title')&.content.presence || page.label
    }

    button_link = cms_fragment_render('button-link', page)
    button_text = cms_fragment_render('button-text', page)
    if button_link.present? && button_text.present?
      locals[:button_link] = button_link
      locals[:button_text] = button_text
    end

    locals
  end
end
