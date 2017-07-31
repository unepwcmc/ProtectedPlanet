class Api::V3::NetworksController < ApplicationController
  def bounds
    network = Network.find_by(id: params[:id])
    render json: network.bounds
  end
end
