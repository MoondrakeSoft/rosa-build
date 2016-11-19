namespace :load do
	task :defaults do
		set :redis_config_file,		-> { '/etc/redis.conf' }
		set :redis_roles,					-> { 'app' }
		set :redis_config,				{
			'bind'									=> nil,
			'unixsocket' 						=> '/run/redis/redis.sock',
			'unixsocketperm' 				=> '770'
		}
	end
end

namespace :redis do

	desc 'Customizes redis configuration to our instance'
	task :config do
		arguments = [:sed]
		config =fetch(:redis_config) 
		#arguments.push(config["unixsocket"])
		#arguments.push("#{key}: #{value}")
		config.each{|key, value|
			key = value.nil? ? "bind 127.0.0.1" : key
			arguments.push(value.nil? ? "-e 's|^\\(#{key}\\)|# \\1 |g'" : "-e 's|^# \\(#{key}\\) .*|\\1 #{value}|g'")
		}
		arguments.push("-i #{fetch :redis_config_file}")
		on roles fetch(:redis_roles) do
			sudo(*arguments)
		end

	end
end
