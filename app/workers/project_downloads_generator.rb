class ProjectDownloadsGenerator
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform project_id
    project = Project.find project_id
    wdpa_ids = Set.new project.items.flat_map(&:wdpa_ids)

    Download.generate "project_#{project.id}_all", wdpa_ids.to_a
  end
end
