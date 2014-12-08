class Download::Requesters::Project < Download::Requesters::Base
  def initialize project_id
    @project_id = project_id
  end

  def request
    unless ['ready', 'generating'].include? generation_info['status']
      DownloadWorkers::Project.perform_async @project_id
    end

    {'token' => identifier}.merge(generation_info)
  end

  def domain
    'project'
  end

  private

  def identifier
    @project_id
  end
end

