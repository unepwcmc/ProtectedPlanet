require_relative '../test_helper'

class CallToActionTest < ActiveSupport::TestCase

  def test_fixtures_validity
    CallToAction.all.each do |cta|
      assert cta.valid?, cta.errors.inspect
    end
  end

  def test_validation
    cta = CallToAction.new
    assert cta.invalid?
    assert_equal [:title, :summary, :url], cta.errors.keys
  end

  def test_creation
    assert_difference 'CallToAction.count' do
      CallToAction.create(
        css_class: 'css_class',
        title: 'test title',
        summary: 'test summary',
        url: 'test url'
      )
    end
  end

end
