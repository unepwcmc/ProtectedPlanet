# frozen_string_literal: true

class TestLogInImportSidekiq
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: :import, backtrace: true

  def perform
    Rails.logger.warn('A log in TestLogInImportSidekiq.perform')
  end
end
