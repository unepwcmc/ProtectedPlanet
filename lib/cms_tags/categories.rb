class Categories < ComfortableMexicanSofa::Content::Tag::Fragment
  def initialize(context:, params: [], source: nil)
    super
    @group_name = options['group_name']
    @categories = Comfy::Cms::PageCategory.where(group_name: @group_name)
  end
  
  def form_field(object_name, view, index)
    options = { id: form_field_id, class: "form-control" }
  
    input = view.send(:collection_check_boxes, :page, :page_category_ids, @categories, :id, :label, options)
            
    yield input
  end

  private

  def parse_content(category)
    return false if fragment.content.blank?
    fragment.content.split(' ').include?(category)
  end

end

ComfortableMexicanSofa::Content::Renderer.register_tag(
    :categories, Categories
)
  