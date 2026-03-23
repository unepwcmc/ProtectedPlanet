FactoryGirl.define do
  factory :pame_evaluation do
    # `method` clashes with Ruby's Kernel#method, so define explicitly
    add_attribute(:method) { 'METT' }
    asmt_year 2020
    asmt_id 1
  end
end


