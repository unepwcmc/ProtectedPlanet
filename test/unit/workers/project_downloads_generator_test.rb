class ProjectDownloadsGeneratorWorkerTest < ActiveSupport::TestCase
  test '.perform calls Download.generate with the wdpa_ids of all items in the
   project with the given project_id' do
    pa = FactoryGirl.create(:protected_area)
    country = FactoryGirl.create(:country)
    region = FactoryGirl.create(:region)
    project = FactoryGirl.create(:project,
      protected_areas: [pa], countries: [country], regions: [region]
    )

    wdpa_ids = project.items.flat_map(&:wdpa_ids).uniq
    Download.expects(:generate).with("project_#{project.id}_all", wdpa_ids)

    ProjectDownloadsGenerator.new.perform project.id
  end
end
