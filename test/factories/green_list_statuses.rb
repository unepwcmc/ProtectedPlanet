# frozen_string_literal: true

FactoryGirl.define do
  factory :green_list_status do
    gl_status { 'Green Listed' }
    gl_expiry { 1.year.from_now.to_date }
    gl_link { 'https://iucngreenlist.org/example' }

    trait :candidate do
      gl_status { 'Candidate' }
    end

    trait :relisted do
      gl_status { 'Relisted' }
    end
  end
end
