# Capistrano plugin hook to set default values
namespace :load do
  task :defaults do
    set :sneakers_systemd_role, fetch(:sneakers_systemd_role, :app)
    set :sneakers_systemd_use_hooks, fetch(:sneakers_systemd_use_hooks, false)
  end
end

# Integrate sneakers hooks into Capistrano
namespace :deploy do
  before :starting, :add_sneakers_systemd_hooks do
    invoke 'sneakers_systemd:add_hooks' if fetch(:sneakers_systemd_use_hooks)
  end
end

namespace :sneakers_systemd do
  # NOTE: no `desc` here to avoid publishing this task in the `cap -T` list
  task :add_hooks do
    after 'deploy:failed', 'sneakers_systemd:restart'
    after 'deploy:published', 'sneakers_systemd:start'
    after 'deploy:starting', 'sneakers_systemd:stop'
  end

  desc 'Stop running workers gracefully'
  task :stop do
    on roles fetch(:sneakers_systemd_role) do
      sudo :systemctl, 'stop', 'sneakers'
    end
  end

  desc 'Start workers'
  task :start do
    on roles fetch(:sneakers_systemd_role) do
      sudo :systemctl, 'start', 'sneakers'
    end
  end

  desc 'Restart workers'
  task :restart do
    on roles fetch(:sneakers_systemd_role) do
      sudo :systemctl, 'restart', 'sneakers', raise_on_non_zero_exit: false
    end
  end
end
