# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :protected_area do
    sequence(:site_id) { |n| n }
    legal_status_updated_at Date.new(2014, 1, 1)
    association :designation, factory: :designation, name: 'My designation'
    association :iucn_category, factory: :iucn_category, name: 'My IUCN category'
    association :legal_status, factory: :legal_status, name: 'My legal status'
    association :governance, factory: :governance, name: 'My governance'
  end
end
