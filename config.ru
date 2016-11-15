# config valid only for current version of Capistrano
lock '3.6.1'


set :application, 'rosa_build'
set :repo_url, 'git@github.com:MoondrakeSoft/rosa-build.git'

# Default branch is :master
set :branch, ENV['branch'] || 'proyvind-docker'

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/srv/#{fetch :application}"

# Default value for :scm is :git
set :scm, :git

set :rvm_ruby_string, 'ruby-2.2.4'

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
set :pty, true
set :ssh_options, forward_agent: true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []) + %w(
  .env
  config/database.yml
  config/application.yml
  config/newrelic.yml
)

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []) + %w(
  log
  tmp/pids
  tmp/cache
  tmp/sockets
  vendor/bundle
  public/downloads
  public/sitemaps
)

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 3


set :puma_preload_app, true
set :puma_threads, [16, 16]
set :puma_workers, 7
set :puma_default_control_app, "unix://#{shared_path}/tmp/sockets/pumactl.sock"
set :puma_conf, "#{shared_path}/config/puma.rb"
set :puma_init_active_record, true

role :resque_worker, "localhost"
role :resque_scheduler, "localhost"

set :workers,{"my_queue_name" => 4} 
set :resque_log_file, "/tmp/resque.log"
set :resque_environment_task, true
set :resque_dynamic_schedule, true

namespace :deploy do

  desc "Setup config files (first time setup)"
  task :setup do
    on roles(:app) do
      execute "mkdir -p #{shared_path}/config"
      execute "mkdir -p #{shared_path}/tmp/pids"
      execute "touch #{shared_path}/.env"

      %w(database application newrelic).each do |config|
	{
	  "config/#{config}.yml.sample" => "config/#{config}.yml"
	}.each do |src, target|
	  unless test("[ -f #{shared_path}/#{target} ]")
	    upload! src, "#{shared_path}/#{target}"
	  end
	end
      end
    end
  end

  desc 'Copy compiled assets'
  task :copy_assets do
    on roles(:app) do
      %w(new_application-*.css new_application-*.css.gz new_application-*.js new_application-*.js.gz).each do |f|
	asset_glob = "#{fetch :shared_path}/assets/#{f}"
	asset_file = capture %Q{ruby -e "print Dir.glob('#{asset_glob}').max_by { |file| File.mtime(file) }"}
	puts asset_file
	if asset_file
	  run "ln -fs #{asset_file} #{fetch :shared_path}/assets/#{ f.gsub('-*', '') }"
	else
	  error "Error #{f} asset does not exist"
	end
      end
    end
  end
end

#FIXME
#after "deploy:finalize_update", "deploy:symlink_all"
#after "deploy:update_code", "deploy:migrate"


# Resque
#after "deploy:stop",    "resque:stop"
#after "resque:stop",    "resque:scheduler:stop"
#after "deploy:start",   "resque:start"
#after "resque:start",    "resque:scheduler:start"
#after "deploy:restart", "resque:restart"
#after "resque:restart",    "resque:scheduler:restart"
#
#after "deploy:restart", "deploy:cleanup"
#after "deploy:cleanup", "deploy:copy_assets"



namespace :rake_tasks do
  on roles(:app) do
    within release_path do
      with rails_env: fetch(:rails_env) do
	execute :rake, 'db:seeds'
      end
    end
  end
end

namespace :update do
  desc "Copy remote production shared files to localhost"
  task :shared do
    run_locally "rsync --recursive --times --rsh=ssh --compress --human-readable --progress #{user}@#{domain}:#{shared_path}/shared_contents/uploads public/uploads"
  end

  desc "Dump remote production postgresql database, rsync to localhost"
  task :postgresql do
    get("#{current_path}/config/database.yml", "tmp/database.yml")

    remote_settings = YAML::load_file("tmp/database.yml")[rails_env]
    local_settings = YAML::load_file("config/database.yml")["development"]


    run "export PGPASSWORD=#{remote_settings["password"]} && pg_dump --host=#{remote_settings["host"]} --port=#{remote_settings["port"]} --username #{remote_settings["username"]} --file #{current_path}/tmp/#{remote_settings["database"]}_dump -Fc #{remote_settings["database"]}"

    run_locally "rsync --recursive --times --rsh=ssh --compress --human-readable --progress #{user}@#{domain}:#{current_path}/tmp/#{remote_settings["database"]}_dump tmp/"

    run_locally "dropdb -U #{local_settings["username"]} --host=#{local_settings["host"]} --port=#{local_settings["port"]} #{local_settings["database"]}"
    run_locally "createdb -U #{local_settings["username"]} --host=#{local_settings["host"]} --port=#{local_settings["port"]} -T template0 #{local_settings["database"]}"
    run_locally "pg_restore -U #{local_settings["username"]} --host=#{local_settings["host"]} --port=#{local_settings["port"]} -d #{local_settings["database"]} tmp/#{remote_settings["database"]}_dump"
  end

  desc "Dump all remote data to localhost"
  task :all do
    # update.shared
    update.postgresql
  end
end
