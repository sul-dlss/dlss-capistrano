# Capistrano plugin hook to set default values
namespace :load do
  task :defaults do
    set :racecar_systemd_role, fetch(:racecar_systemd_role, :app)
    set :racecar_systemd_use_hooks, fetch(:racecar_systemd_use_hooks, false)
  end
end

# Integrate racecar hooks into Capistrano
namespace :deploy do
  before :starting, :add_racecar_systemd_hooks do
    invoke 'racecar_systemd:add_hooks' if fetch(:racecar_systemd_use_hooks)
  end
end

namespace :racecar_systemd do
  # NOTE: no `desc` here to avoid publishing this task in the `cap -T` list
  task :add_hooks do
    after 'deploy:failed', 'racecar_systemd:restart'
    after 'deploy:published', 'racecar_systemd:start'
    after 'deploy:starting', 'racecar_systemd:stop'
  end

  desc 'Stop running workers gracefully'
  task :stop do
    on roles(fetch(:racecar_systemd_role)) do
      sudo :systemctl, 'stop', 'racecar'
    end
  end

  desc 'Start workers'
  task :start do
    on roles(fetch(:racecar_systemd_role)) do
      sudo :systemctl, 'start', 'racecar'
    end
  end

  desc 'Restart workers'
  task :restart do
    on roles(fetch(:racecar_systemd_role)) do
      sudo :systemctl, 'restart', 'racecar', raise_on_non_zero_exit: false
    end
  end
end
