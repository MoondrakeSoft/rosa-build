require 'airbrake'

Airbrake.configure do |config|
  config.project_id = APP_CONFIG['airbrake']['id']
  config.project_key = APP_CONFIG['airbrake']['secret']
  config.host    = APP_CONFIG['airbrake']['host']
end
