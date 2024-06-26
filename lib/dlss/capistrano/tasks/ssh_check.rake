desc "check ssh connections to all app servers"
task :ssh_check do
  on roles(:app), in: :sequence do
    execute
  end
end
