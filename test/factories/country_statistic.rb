# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :country_statistic do
    association :country, factory: :country, name: 'My country'
  end
end
