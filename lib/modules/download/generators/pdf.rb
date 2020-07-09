class Download::Generators::Pdf < Download::Generators::Base
  include ActionController::UrlFor

  TYPE = 'pdf'

  def initialize(zip_path, identifier)
    @zip_path = zip_path
    @identifier = identifier
  end

  def generate
    rasterizer = Rails.root.join('vendor/assets/javascripts/rasterize.js')
    url = url_for(params)

    `phantomjs #{rasterizer} '#{url}' #{dest_pdf} A4`
  end

  private

  # Remove extension and add the pdf one
  def dest_pdf
    @zip_path[0..-5] << '.pdf'
  end

  def params
    { 
      'controller' => controller,
      'action' => :show,
      key => @identifier,
      'for_pdf' => true
    }
  end

  def key
    id_is_integer? ? 'id' : 'iso' 
  end

  def controller
    id_is_integer? ? 'protected_areas' : 'country'
  end

  def id_is_integer?
    # 'a-non-numeric-string'.to_i == 0
    # 0.to_s != 'a-non-numeric-string'
    @identifier.to_i.to_s == @identifier
  end
end