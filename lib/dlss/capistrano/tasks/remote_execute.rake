desc "execute command on all servers"
task :remote_execute, :command do |_task, args|
  raise ArgumentError, 'remote_execute task requires an argument' unless args[:command]

  on roles(:all) do |host|
    info args[:command] if fetch(:log_level) == :debug
    info "#{host}:\n#{capture(args[:command])}"
  end
end
