class ProjectDownloadsGenerator
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform project_id
    project = Project.find project_id
    wdpa_ids = Set.new project.items.flat_map(&:wdpa_ids)

    while_generating project.id do
      Download.generate "project_#{project.id}_all", {wdpa_ids: wdpa_ids.to_a}
      links project.id
    end
  end

  private

  def while_generating id
    $redis.set("projects:#{id}:all", 'generating')
    $redis.set("projects:#{id}:all", yield)
  end


  def links id
    ['csv', 'shp', 'kml'].each_with_object({}) do |type, hash|
      hash[type] = Download.link_to "project_#{id}_all", type
    end.to_json
  end
end
