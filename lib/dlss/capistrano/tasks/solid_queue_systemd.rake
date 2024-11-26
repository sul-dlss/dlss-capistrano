# Capistrano plugin hook to set default values
namespace :load do
  task :defaults do
    set :solid_queue_systemd_role, fetch(:solid_queue_systemd_role, :app)
    set :solid_queue_systemd_use_hooks, fetch(:solid_queue_systemd_use_hooks, false)
  end
end

# Integrate solid_queue hooks into Capistrano
namespace :deploy do
  before :starting, :add_solid_queue_systemd_hooks do
    invoke 'solid_queue_systemd:add_hooks' if fetch(:solid_queue_systemd_use_hooks)
  end
end

namespace :solid_queue_systemd do
  # NOTE: no `desc` here to avoid publishing this task in the `cap -T` list
  task :add_hooks do
    after 'deploy:failed', 'solid_queue_systemd:restart'
    after 'deploy:published', 'solid_queue_systemd:start'
    after 'deploy:starting', 'solid_queue_systemd:stop'
  end

  desc 'Stop running workers gracefully'
  task :stop do
    on roles(fetch(:solid_queue_systemd_role)) do
      sudo :systemctl, 'stop', 'solid_queue'
    end
  end

  desc 'Start workers'
  task :start do
    on roles(fetch(:solid_queue_systemd_role)) do
      sudo :systemctl, 'start', 'solid_queue'
    end
  end

  desc 'Restart workers'
  task :restart do
    on roles(fetch(:solid_queue_systemd_role)) do
      sudo :systemctl, 'restart', 'solid_queue', raise_on_non_zero_exit: false
    end
  end
end
