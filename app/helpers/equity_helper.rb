module EquityHelper
  def tabs
    @tabs = get_cms_tabs(2).to_json
  end

  def pa_pages
    @pa_pages ||= @cms_page.children.first.children
  end

  def text
    @text ||= cms_fragment_content(:text, @pa_pages.first)
  end

  def protected_areas
    pa_pages.published.map do |child|
      {
        title: child.label,
        text: parsed_text(text),
        url: pa_link(child.label),
        image: include_image(cms_fragment_content(:text, child))
      }
    end
  end

  # Where the site exists but the name is misspelt
  EDGE_CASES = {
    'Port Campbell National Park': 2403,
    'Banff National Park of Canada': 615,
    'Sierra Nevada De Santa Marta': 132,
    'Ostional (estatal)': 12_244
  }.freeze

  def pa_link(label)
    wdpaid = ''
    name_of_site = label.split(',').first.squish

    wdpaid = if EDGE_CASES.key?(name_of_site.to_sym)
               EDGE_CASES[name_of_site.to_sym]
             else
               ProtectedArea.find_by(name: name_of_site)&.wdpa_id
             end

    URI.join(root_url, wdpaid.to_s)
  end

  def include_image(pa_page)
    Nokogiri::HTML(pa_page).css('img').attr('src').value
  end

  def parsed_text(text)
    Nokogiri::HTML(text).css('p').last.text
  rescue StandardError
    'No description available.'
  end
end
