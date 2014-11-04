class HomeController < ApplicationController
  after_filter :enable_caching

  def index
    if filtered?
      @search = Search.search '', {filters: filters}
    end
  end

  private

  def filters
    params.stringify_keys.slice('marine', 'iucn_category')
  end

  def filtered?
    params.include?('marine') || params.include?('iucn_category')
  end
end
