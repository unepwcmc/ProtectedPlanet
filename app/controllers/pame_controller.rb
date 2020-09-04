class PameController < ApplicationController
  include Concerns::Tabs

  DEFAULT_PARAMS =
  {
    requested_page: 1,
    filters: []
  }.to_json

  # Format for this date is: Month and Year (4 digits)
  UPDATED_AT = "July 2019".freeze

  def index
    @table_attributes = PameEvaluation::TABLE_ATTRIBUTES.to_json
    @filters = PameEvaluation.filters_to_json
    @sources = PameEvaluation.sources_to_json
    @json = PameEvaluation.paginate_evaluations(DEFAULT_PARAMS).to_json
    @updated_at = UPDATED_AT

    @tabs = get_tabs.to_json
  end

  def list
    @evaluations = PameEvaluation.paginate_evaluations(params.to_json)

    render json: @evaluations
  end

  def download
    send_data PameEvaluation.to_csv(params.to_json), {
                type: "text/csv; charset=utf-8; header=present",
                disposition: "attachment",
                filename: "protectedplanet-pame.csv" }
  end
end

