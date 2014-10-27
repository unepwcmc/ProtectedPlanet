FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password 'whatapassword123'
    password_confirmation 'whatapassword123'
  end
end