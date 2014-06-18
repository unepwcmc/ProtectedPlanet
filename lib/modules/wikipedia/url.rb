class Wikipedia::URL
  WIKIPEDIA_HOSTNAME = -> (lang) {"#{lang}.wikipedia.org"}
  DEFAULT_OPTIONS = {
    language: 'en'
  }

  def self.build article, options={}
    options = DEFAULT_OPTIONS.merge options
    "http://#{WIKIPEDIA_HOSTNAME.call(options[:language])}/wiki/#{title_for_url(article.title)}"
  end

  private

  def self.title_for_url title
    title.gsub(/\s+/, '_')
  end

end
