# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :protected_area_parcel do
    sequence(:wdpa_id) { |n| n }
    wdpa_pid { wdpa_id.to_s }
    legal_status_updated_at Date.new(2025, 4, 1)
    association :designation, factory: :designation, name: 'My designation'
    association :iucn_category, factory: :iucn_category, name: 'My IUCN category'
    association :legal_status, factory: :legal_status, name: 'My legal status'
    association :governance, factory: :governance, name: 'My governance'
  end
end
