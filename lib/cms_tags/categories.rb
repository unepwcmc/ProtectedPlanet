class Categories < ComfortableMexicanSofa::Content::Tag::Fragment
  def initialize(context:, params: [], source: nil)
    super
    @group_name = params.first
    @categories = Comfy::Cms::LayoutCategory.find_by(label: @group_name).page_categories
  end
  
  def form_field(object_name, view, index)
    options = { id: form_field_id, class: "form-control" }
  
    input = view.collection_check_boxes(:page, :page_category_ids, @categories, :id, :label, options) do |b|
      view.content_tag(:div, class: "form-check form-check-inline") do
        view.concat b.check_box(class: "form-check-input") 
        view.concat b.label(class: "form-check-label")
      end
    end

    yield input
  end
end

ComfortableMexicanSofa::Content::Renderer.register_tag(
    :categories, Categories
)
  