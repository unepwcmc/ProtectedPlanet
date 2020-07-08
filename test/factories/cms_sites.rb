
FactoryGirl.define do
  factory :cms_site,   class: 'comfy/cms/site'   do;
    label 'protectedplanet'
    identifier 'protectedplanet'
    hostname 'localhost'
    path '/'
    locale 'en'
  end
end
