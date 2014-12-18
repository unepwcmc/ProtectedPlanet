class DownloadWorkers::Project < DownloadWorkers::Base
  def perform project_id
    @project_id = project_id

    while_generating(key(project_id)) do
      generate_download
      {status: 'ready', filename: filename(project.id)}.to_json
    end
  end

  protected

  def generate_download
    Download.generate filename(project.id), {wdpa_ids: wdpa_ids.to_a}
  end

  def domain
    'project'
  end

  def wdpa_ids
    @wdpa_ids ||= Set.new project.items.flat_map(&:wdpa_ids)
  end

  def project
    @project ||= Project.find @project_id
  end
end
