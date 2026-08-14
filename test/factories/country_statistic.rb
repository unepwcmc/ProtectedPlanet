# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :country_statistic do
    association :country, factory: :country, name: 'My country'
  end
end
