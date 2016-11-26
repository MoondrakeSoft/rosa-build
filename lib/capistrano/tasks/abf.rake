set :pkg_resolver, %w(yum install -y)
set :pkg_repo_deps, nil
set :pkg_dependencies, %w(
git-core
pkgconfig(icu-i18n)
gcc
gcc-c++
file-devel
pkgconfig(ruby)
pkgconfig(libxml-2.0)
pkgconfig(libxslt)
postgresql-devel
nginx
postfix
pkgconfig(python2)
crontabs
pkgconfig(openssl)
openssl
redis
)

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

namespace :abf do

  desc 'Initialize environment'
  task :create_users do
    on roles(:app) do
      sudo("install", "-d", '--group=rosa', '--owner=rosa', '--mode=755', fetch(:deploy_to))
      sudo("adduser", "-G", "rosa", "git")
      sudo("usermod", "-G", "git,redis", "rosa")
    end
  end

  desc 'Install system dependencies'
  task :install_deps do
    on roles(:app) do
      repos = fetch(:pkg_repo_deps)
      if not repos.nil?
	args = fetch(:pkg_resolver)
	args.push(repos.map!{ |pkg| "'"+pkg+"'"})
	sudo(args)
      end
      args = fetch(:pkg_resolver)
      args.push(fetch(:pkg_dependencies).map!{ |pkg| "'"+pkg+"'"})
      sudo(args)
    end
  end

end

namespace :db do

  desc 'Load the seed data from db/seeds.rb'
  task :seed do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'db:seed'
        end
      end
    end
  end
end
