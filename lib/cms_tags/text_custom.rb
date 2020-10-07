class TextCustom < ComfortableMexicanSofa::Content::Tag::Fragment

  def initialize(context:, params: [], source: nil)
    super
    @required = parse_required
    @max_length = options['max_length'] || '167'
  end

  def form_field(object_name, view, index)
    name    = "#{object_name}[fragments_attributes][#{index}][content]"
    options = { id: form_field_id, class: "form-control" , maxlength: @max_length, required: @required }
    input   = view.send(:text_field_tag, name, content, options)

    yield input
  end

  private

  def parse_required
    options['required'] == 'true' ? 'required' : nil
  end
end

ComfortableMexicanSofa::Content::Renderer.register_tag(
  :text_custom, TextCustom
)
