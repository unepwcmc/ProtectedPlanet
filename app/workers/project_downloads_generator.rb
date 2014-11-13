class ProjectDownloadsGenerator
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform project_id
    @project = Project.find project_id
    wdpa_ids = Set.new @project.items.flat_map(&:wdpa_ids)

    while_generating @project.id do
      Download.generate "project_#{@project.id}_all", {wdpa_ids: wdpa_ids.to_a}
      {status: 'completed', links: links(@project.id)}.to_json
    end
  end

  private

  def filename
    "project_#{@project.id}_all"
  end

  def while_generating
    $redis.set("projects:#{@project.id}:all", {status: 'generating'}.to_json)
    $redis.set("projects:#{@project.id}:all", yield)
  end


  def links id
    ['csv', 'shp', 'kml'].each_with_object({}) do |type, hash|
      hash[type] = Download.link_to filename, type
    end.to_json
  end
end
