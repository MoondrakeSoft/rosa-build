set :branch, "ui"

set :domain, "abf.warpc.ru" # "195.19.76.12"
set :port, 1822

role :app, domain
role :web, domain
role :db,  domain, :primary => true

set :application, "rosa_build_#{stage}"
set :deploy_to, "/srv/#{application}"

set :unicorn_port, 8082

before "deploy:restart", "deploy:stub_xml_rpc"