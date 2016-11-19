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
