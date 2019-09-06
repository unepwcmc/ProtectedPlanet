require 'test_helper'

class Aichi11TargetTest < ActiveSupport::TestCase
  test 'it only creates one instance' do
    FactoryGirl.create(:aichi11_target)

    assert_raise(ActiveRecord::RecordNotUnique) { FactoryGirl.create(:aichi11_target) }
  end
end
