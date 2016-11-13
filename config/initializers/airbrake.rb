require 'airbrake'

Airbrake.configure do |config|
  config.api_key = APP_CONFIG['keys']['airbrake_api_key']
  config.host    = 'localhost'
  config.port    = 8080
  config.secure  = config.port == 443
end
