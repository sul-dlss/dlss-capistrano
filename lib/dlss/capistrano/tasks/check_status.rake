# Capistrano plugin hook to set default values
namespace :load do
  task :defaults do
    set :check_status_roles, fetch(:check_status_roles, [:web])
    set :check_status_path, fetch(:check_status_path, '/status/all')
  end
end

desc 'Run status checks'
task :check_status do
  on roles(fetch(:check_status_roles)), in: :sequence do |host|
    status_url = "https://#{host}#{fetch(:check_status_path)}"

    info "Checking status at #{status_url}"
    status_body = capture("curl #{status_url}")

    if status_body.nil?
      error 'Endpoint could not be reached'
    elsif status_body.match?(/FAILED/)
      error status_body.lines.grep(/FAILED/).join
    elsif !status_body.match?(/PASSED/)
      error status_body
    else
      info SSHKit::Color.new($stdout).colorize('All checks passed!', :green)
    end
  end
end
