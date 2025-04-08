# coding: utf-8
require 'test_helper'

class ProtectedAreaParcelTest < ActiveSupport::TestCase
  test ".save creates a slug attribute consisting of parameterized name
  and designation" do
   designation = FactoryGirl.create(:designation, name: 'Protected Area')
   protected_area = ProtectedArea.create(
    wdpa_id: 123, 
    wdpa_pid: "123_A",
    name: 'Finn and Jake Land',
    designation: designation)
   assert_equal '123-123_A-finn-and-jake-land-protected-area', protected_area.slug
 end

end
