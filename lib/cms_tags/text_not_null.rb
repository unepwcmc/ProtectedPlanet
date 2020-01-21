class TextNotNull < ComfortableMexicanSofa::Content::Tag::Fragment

  def form_field(object_name, view, index)
    name    = "#{object_name}[fragments_attributes][#{index}][content]"
    options = { id: form_field_id, class: "form-control", required: 'required' }
    input   = view.send(:text_field_tag, name, content, options)

    yield input
  end
end

ComfortableMexicanSofa::Content::Renderer.register_tag(
  :text_not_null, TextNotNull
)
