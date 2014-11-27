class Download::Requesters::Project < Download::Requesters::Base
  def initialize project
    @project = project
  end

  def request
    generation_status = $redis.get(download_key)
    ProjectDownloadsGenerator.perform_async @project.id if generation_status.nil?

    JSON.parse(generation_status) rescue {}
  end

  private

  def download_key
    "downloads:projects:#{@project.id}:all"
  end
end

