class DownloadCompleteMailer < ApplicationMailer
  def create filename, email
    @filename = filename

    mail(
      to: email,
      subject: '[Protected Planet] Your download is ready'
    )
  end
end
