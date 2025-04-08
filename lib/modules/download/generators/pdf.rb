class Download::Generators::Pdf < Download::Generators::Base
  include Routeable

  TYPE = 'pdf'

  def initialize(zip_path, identifier)
    @zip_path = zip_path
    @identifier = identifier
  end

  def generate
    rasterizer = Rails.root.join('vendor/assets/javascripts/rasterize.js')
    url = url_for(params)
    `node --trace-warnings #{rasterizer} '#{url}' #{dest_pdf}`

    # Can reuse shared methods? TODO
    system("zip -j #{@zip_path} #{dest_pdf}") and add_attachments
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
    return 'protected_areas' if id_is_integer?
    @identifier.length == 3 ? 'country' : 'region'
  end

  def id_is_integer?
    # 'a-non-numeric-string'.to_i == 0
    # 0.to_s != 'a-non-numeric-string'
    @identifier.to_i.to_s == @identifier
  end
end
