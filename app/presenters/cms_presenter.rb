class CmsPresenter
  def initialize page
    @page = page
  end

  def all_versions
    old = collect_older_versions(@page)
    new = collect_newer_versions(@page)

    (new.reverse << @page).concat(old)
  end

  def most_recent_version?
    Comfy::Cms::Page.where(older_version_id: @page.id).count.zero?
  end

  def self.all_by_year
    Comfy::Cms::Page.order(:created_at).pluck(:created_at).group_by(&:year)
  end

  private

  def collect_older_versions page, collection=[]
    if older_version = Comfy::Cms::Page.find_by_id(page.older_version_id)
      collection << older_version
      return collect_older_versions(older_version, collection)
    end

    collection
  end

  def collect_newer_versions page, collection=[]
    if newer_version = Comfy::Cms::Page.find_by_older_version_id(page.id)
      collection << newer_version
      return collect_newer_versions(newer_version, collection)
    end

    collection
  end
end
