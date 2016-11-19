namespace :deploy do

  desc "Setup config files (first time setup)"
  task :setup do
    on roles(:app) do
      execute "mkdir -p #{shared_path}/config"
      execute "mkdir -p #{shared_path}/tmp/pids"
      %W(.env.local .env.#{fetch :rails_env}).each do |dotenv_rails|
	if File.exists?(dotenv_rails)
	  upload! dotenv_rails, "#{shared_path}/#{dotenv_rails}"
	else
	  execute "touch #{shared_path}/#{dotenv_rails}"
	end
      end

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

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end
end
