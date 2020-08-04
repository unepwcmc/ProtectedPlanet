
FactoryGirl.define do
  factory :cms_page,   class: 'comfy/cms/page'   do;
    label 'page'
    slug 'page'
    layout 'test'
  end
end
