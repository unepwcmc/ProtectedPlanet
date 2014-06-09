# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :country do
    name "MyText"
    iso "MyString"
    iso_3 "MyString"
  end
end
