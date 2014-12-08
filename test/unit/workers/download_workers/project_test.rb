require 'test_helper'

class DownloadWorkersProjectTest < ActiveSupport::TestCase
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

    SavedSearch.any_instance.stubs(:population_completed?).returns(true)
    Download.expects(:generate).with("projects_#{project.id}_all", {wdpa_ids: [pa.wdpa_id]})

    DownloadWorkers::Project.new.perform project.id
  end
end
