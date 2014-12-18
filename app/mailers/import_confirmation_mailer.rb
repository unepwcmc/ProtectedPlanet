class ImportConfirmationMailer < ActionMailer::Base
  default from: "no-reply@unep-wcmc.org"
  layout 'mailer'

  def create import
    @token = import.token
    @confirmation_key = import.confirmation_key

    mail(
      to: email_addresses,
      subject: "[Protected Planet] Your import is ready and needs confirming"
    )
  end

  private

  def email_addresses
    Rails.application.secrets.import_confirmation_emails
  end
end
