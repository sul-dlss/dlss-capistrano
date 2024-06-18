# Capistrano plugin hook to set default values

namespace :load do
  task :defaults do
    ssh_options = fetch(:ssh_options, {}).merge(
      auth_methods: %w(gssapi-with-mic publickey hostbased password keyboard-interactive)
    )
    set :ssh_options, **ssh_options
  end
end

desc "execute command on all servers"
task :remote_execute, [:command] => ['controlmaster:setup', 'otk:generate'] do |_task, args|
  raise ArgumentError, 'remote_execute task requires an argument' unless args[:command]

  # see https://github.com/mattbrictson/airbrussh/tree/v1.5.2?tab=readme-ov-file#capistrano-34x
  Airbrussh.configure do |config|
    config.truncate = false
  end

  on roles(:all) do |host|
    info args[:command] if fetch(:log_level) == :debug
    info "#{host}:\n#{capture(args[:command])}"
  end
end
