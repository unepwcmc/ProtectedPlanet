class DownloadCompleteMailer < ActionMailer::Base
  default from: "no-reply@unep-wcmc.org"
  layout 'mailer'

  def create filename, email
    @filename = filename

    mail(
      to: email,
      subject: '[Protected Planet] Your download is ready'
    )
  end
end
