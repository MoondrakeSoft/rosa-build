source 'https://rubygems.org'

gem 'rails'

gem 'activeadmin',                      github: 'activeadmin'
gem 'pg'
gem 'schema_plus'
########
gem 'devise', '>= 4.4.1'
gem 'omniauth-github'
gem 'pundit'
gem 'rbtrace'

gem 'paperclip'
gem 'sinatra', :require => nil
gem 'sidekiq'
gem 'kiqit', github: 'DuratarskeyK/kiqit'
gem 'sidekiq-scheduler', '~> 2.0'
gem 'sidekiq-failures'
gem 'russian'
gem 'state_machines-activerecord'
gem 'redis-rails'

#gem 'newrelic_rpm'

gem 'jbuilder'
gem 'sprockets'
gem 'will_paginate'
gem 'meta-tags', require: 'meta_tags'
gem 'haml-rails'
gem 'ruby-haml-js'
gem 'slim'
gem 'simple_form', '3.1.0.rc2'
gem 'friendly_id'

gem 'rack-throttle', '~> 0.3.0'
gem 'rest-client'
gem 'ohm', '~> 1.3.2' # Ohm 2 breaks the compatibility with previous versions.
gem 'ohm-expire', '~> 0.1.3'

gem 'pygments.rb'

gem 'attr_encrypted'

# AngularJS related stuff
gem 'angular-rails-templates'
gem 'ng-rails-csrf'
gem 'angular-i18n'
gem 'js-routes'
gem 'soundmanager-rails'
gem 'ngannotate-rails'

gem 'time_diff'

gem 'sass-rails'
gem 'coffee-rails'
gem 'dotenv-rails'

gem 'compass-rails'
gem 'uglifier'
gem 'mini_racer'
#gem 'therubyracer', platforms: [:mri, :rbx]
#gem 'therubyrhino', platforms: :jruby

source 'https://rails-assets.org' do
  gem 'rails-assets-notifyjs'
end

gem 'rack-utf8_sanitizer'
gem 'redis-semaphore'

#github api
gem "octokit", "~> 4.0"
gem 'faraday-http-cache'

group :production do
  gem 'airbrake'
  gem 'puma'
end

group :development do
  gem 'mailcatcher' # 'letter_opener'
  gem 'rails3-generators'
  gem 'hirb'
  gem 'shotgun'
  # deploy
  gem 'capistrano', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-rake', require: false
  gem 'capistrano-deploy', require: false
  gem 'capistrano3-nginx', require: false
  gem 'capistrano-sidekiq', require: false, group: :development
  gem 'capistrano3-puma', '1.2.1', require: false
  #gem 'capistrano-rbenv', requires: false
  gem 'rvm1-capistrano3', '1.4.0.1', tag: '1.4.0.1', require: false, github: 'MoondrakeSoft/rvm1-capistrano3'
  # net-ssh requires the following gems for ed25519 support:
  gem 'rbnacl', '>= 3.2', '< 5.0', require: false
  #gem 'rbnacl-libsodium', require: false
  gem 'bcrypt_pbkdf', '>= 1.0', '< 2.0', require: false

  gem 'io-console', require: false
  gem 'state_machines-graphviz'
  # Better Errors & RailsPanel
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'localeapp'
  #gem 'ruby-dbus' if RUBY_PLATFORM =~ /linux/i # Error at deploy
  gem 'rack-mini-profiler', require: false
end

group :development, :test do
  gem 'rspec-rails'
end

group :test do
  gem 'factory_girl_rails'
  gem 'rr'
  gem 'shoulda'
  gem 'shoulda-matchers'
  gem 'mock_redis'
  gem 'webmock'
  gem 'rake'
  gem 'test_after_commit'
  gem 'timecop'
end
