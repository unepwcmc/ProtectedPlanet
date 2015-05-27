require 'test_helper'

class DownloadWorkersProjectTest < ActiveSupport::TestCase
  def setup
    Wdpa::S3.stubs(:current_wdpa_identifier).returns('Jun2015')
  end

  test '.perform calls Download.generate with the wdpa_ids of all items in the
   project with the given project_id' do
    pa = FactoryGirl.create(:protected_area)
    country = FactoryGirl.create(:country)
    region = FactoryGirl.create(:region)
    saved_search = FactoryGirl.create(:saved_search)

    project = FactoryGirl.create(:project,
      protected_areas: [pa],
      countries: [country],
      regions: [region],
      saved_searches: [saved_search]
    )

    SavedSearch.any_instance.stubs(:wdpa_ids).returns([pa.wdpa_id])

    Download.expects(:generate).with("Jun2015_projects_#{project.id}_all", {wdpa_ids: [pa.wdpa_id]})

    DownloadWorkers::Project.new.perform project.id
  end
end
