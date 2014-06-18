# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :designation do
    name "MyString"
    association :jurisdiction, factory: :jurisdiction, name: 'My jurisdiction'
  end
end
