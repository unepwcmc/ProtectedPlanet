require 'test_helper'

class TestWdpaAttribute < ActiveSupport::TestCase
  test '.standardise converts boolean-like values to boolean' do
    assert_equal false, Wdpa::Attribute.standardise('0', as: :boolean),
      "Expected '0' to be converted to false"

    assert_equal true, Wdpa::Attribute.standardise('1', as: :boolean),
      "Expected '1' to be converted to true"

    assert_equal false, Wdpa::Attribute.standardise('trust', as: :boolean),
      "Expected 'trust' to be converted to false"
  end

  test '.standardise converts integer-like values to integers' do
    assert_equal 1, Wdpa::Attribute.standardise('1', as: :integer),
      "Expected '1' to be converted to 1"

    assert_equal 0, Wdpa::Attribute.standardise('abc', as: :integer),
      "Expected 'abc' to be converted to 1"
  end

  test '.standardise converts string-like values to strings' do
    assert_equal 'abc', Wdpa::Attribute.standardise('abc', as: :string),
      "Expected 'abc' to remain as 'abc'"

    assert_equal '1234', Wdpa::Attribute.standardise(1234, as: :string),
      "Expected 1234 to be converted to '1234'"
  end

  test '.standardise converts float-like values to floats' do
    assert_equal 1.43, Wdpa::Attribute.standardise('1.43', as: :float),
      "Expected '1.43' to be converted to 1.43"

    assert_equal 1.0, Wdpa::Attribute.standardise(1, as: :float),
      "Expected 1 to be converted to 1.0"

    assert_equal 0.0, Wdpa::Attribute.standardise('abc', as: :float),
      "Expected 'abc' to be converted to 0.0"
  end

  test '.standardise converts year-like values to dates' do
    assert_equal Date.new(1991), Wdpa::Attribute.standardise('1991', as: :year),
      "Expected '1991' to be converted to date 1991"

    assert_nil Wdpa::Attribute.standardise('Not reported', as: :year),
      "Expected a non-year-looking string to be converted to null"
  end

  test ".standardise raises an error if the specified converter doesn't exist" do
    assert_raises NotImplementedError, "No conversion exists for type 'blue'" do
      Wdpa::Attribute.standardise('carebear', as: :blue)
    end
  end
end
