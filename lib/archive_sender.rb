require 'pony'
require 'sidekiq'

class ArchiveSender
  include Sidekiq::Worker

  def perform(archive_path, recipient_email)
    log_info("Sending archive to #{recipient_email}")
    begin
      Pony.mail(
        to: recipient_email,
        from: 'vakariuk.andrii@chnu.edu.ua',
        subject: 'Ruby Scraper Archive File',
        body: 'Please find the archive attached.',
        attachments: { File.basename(archive_path) => File.read(archive_path) },
        via: :smtp,
        :via_options => {
          :address              => 'smtp.gmail.com',
          :port                 => '587',
          :enable_starttls_auto => true,
          :user_name            => 'vakariuk.andrii@chnu.edu.ua',
          :password             => 'password_see_note',
          :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
          :domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
        }
      )
      log_info("Archive sent successfully to #{recipient_email}")
    rescue => e
      log_error("Error sending archive: #{e.message}", :error)
    end
  end

  private

  def log_info(msg)
    MyApplicationName::LoggerManager.log_info(msg)
  end

  def log_error(msg)
    MyApplicationName::LoggerManager.log_error(msg)
  end
end
