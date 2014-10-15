class Import::ConfirmationController < ApplicationController
  before_filter :verify_key

  def confirm
    render text: ""
  end

  def cancel
    render text: ""
  end

  private

  def import
    @import ||= ImportTools::Import.find(params[:token])
  end

  def verify_key
    unless import.verify_confirmation_key params[:key]
      return render text: "", status: 401
    end
  end
end
