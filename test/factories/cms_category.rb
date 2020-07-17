
FactoryGirl.define do
  factory :cms_category,   class: 'comfy/cms/category'   do;
    label 'cat'
    categorized_type 'badger'
  end
end
