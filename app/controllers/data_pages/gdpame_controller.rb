class DataPages::GdpameController < ApplicationController

  DEFAULT_PARAMS =
  {
    requested_page: 1,
    filters: []
  }.to_json

  def index
    @table_attributes = PameEvaluation::TABLE_ATTRIBUTES
    @filters = PameEvaluation.filters
    @json = PameEvaluation.paginate_evaluations(DEFAULT_PARAMS)

    @tabs_list = helpers.thematic_and_data_area_tabs(@cms_page)
  end

  def list
    @evaluations = PameEvaluation.paginate_evaluations(params.to_json)

    render json: @evaluations
  end

  def download
    send_data PameEvaluation.to_csv(params.to_json), {
                type: 'text/csv; charset=utf-8',
                disposition: 'attachment',
                filename: "protectedplanet-effectiveness-#{Release.current_label}.csv" }
  end
end
