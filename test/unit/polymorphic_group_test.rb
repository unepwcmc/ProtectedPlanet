require 'test_helper'

class PolymorphicGroupTest < ActiveSupport::TestCase
  def setup
    Project.include(PolymorphicGroup)
    Project.polymorphic_group :group, [:protected_areas, :countries]

    @pa = FactoryGirl.create(:protected_area)
    @country = FactoryGirl.create(:country)
    @project = FactoryGirl.create(:project)
  end

  test '.polymorphic_group creates a getter method, linked to the given
   relations' do
    @project.protected_areas << @pa
    @project.countries << @country
    assert_same_elements [@pa, @country], @project.group
  end

  test '.polymorphic_group creates an insert method to populate the given
   relations' do
    @project.group << @pa
    @project.group << @country

    assert_equal [@pa, @country], @project.group
    assert_equal [@pa], @project.protected_areas
    assert_equal [@country], @project.countries
   end
end
