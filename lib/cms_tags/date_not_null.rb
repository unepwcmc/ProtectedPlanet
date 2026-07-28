class ComfortableMediaSurfer::Content::Tags::DateNotNull < ComfortableMediaSurfer::Content::Tags::Datetime

  def form_field(object_name, view, index)
    name    = "#{object_name}[fragments_attributes][#{index}][datetime]"
    options = { id: form_field_id, class: "form-control", data: { "cms-date" => true }, required: 'required' }
    value   = content.present? ? content.to_s(:db) : ""
    input   = view.send(:text_field_tag, name, value, options)

    yield input
  end

end

ComfortableMediaSurfer::Content::Renderer.register_tag(
  :date_not_null, ComfortableMediaSurfer::Content::Tags::DateNotNull
)
