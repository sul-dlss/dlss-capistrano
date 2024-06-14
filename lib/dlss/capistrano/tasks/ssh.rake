desc "ssh to the current directory on the server"
task ssh: 'controlmaster:setup' do
  on roles(:app), :primary => true do |host|
    command = "cd #{fetch(:deploy_to)}/current && exec $SHELL -l"
    puts command if fetch(:log_level) == :debug
    exec "ssh -l #{host.user} #{host.hostname} -p #{host.port || 22} -t '#{command}'"
  end
end
