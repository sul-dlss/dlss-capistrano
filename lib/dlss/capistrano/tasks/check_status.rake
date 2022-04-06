# Capistrano plugin hook to set default values
namespace :load do
  task :defaults do
    set :check_status_roles, fetch(:check_status_roles, [:web])
    set :check_status_path, fetch(:check_status_path, '/status/all')
  end
end

desc 'Run status checks'
task :check_status do
  on roles fetch(:check_status_roles) do |host|
    info "Checking status at https://#{host}#{fetch(:check_status_path)}:"
    puts capture("curl https://#{host}#{fetch(:check_status_path)}")
  end
end
