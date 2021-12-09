class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("SMTP_FROM", 'support@notch8.com')
  layout 'mailer'
end
