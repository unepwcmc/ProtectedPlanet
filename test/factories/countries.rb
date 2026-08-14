# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :country do
    name { "MyText" }
    iso { "MT" }
    iso_3 { "MTX" }
  end
end
