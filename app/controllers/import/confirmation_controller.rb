class Import::ConfirmationController < ApplicationController
  before_filter :verify_key
  after_filter :delete_confirmation_key

  def confirm
    ImportWorkers::MainWorker.perform_async
  end

  def cancel
    import.stop(false)
  end

  private

  def import
    @import ||= ImportTools::Import.find(params[:token], params[:token])
  end

  def delete_confirmation_key
    import.delete_confirmation_key
  end

  def verify_key
    unless import.verify_confirmation_key params[:key]
      return render text: "", status: 401
    end
  end
end
