# Capistrano plugin hook to set default values
namespace :load do
  task :defaults do
    set :sidekiq_systemd_role, fetch(:sidekiq_systemd_role, :app)
    set :sidekiq_systemd_use_hooks, fetch(:sidekiq_systemd_use_hooks, false)
  end
end

# Integrate sidekiq hooks into Capistrano
namespace :deploy do
  before :starting, :add_sidekiq_systemd_hooks do
    invoke 'sidekiq_systemd:add_hooks' if fetch(:sidekiq_systemd_use_hooks)
  end
end

namespace :sidekiq_systemd do
  # NOTE: no `desc` here to avoid publishing this task in the `cap -T` list
  task :add_hooks do
    after 'deploy:failed', 'sidekiq_systemd:restart'
    after 'deploy:published', 'sidekiq_systemd:start'
    after 'deploy:starting', 'sidekiq_systemd:quiet'
    after 'deploy:updated', 'sidekiq_systemd:stop'
  end

  desc 'Stop workers from picking up new jobs'
  task :quiet do
    on roles(fetch(:sidekiq_systemd_role)) do
      sudo :systemctl, 'reload', 'sidekiq-*', raise_on_non_zero_exit: false
    end
  end

  desc 'Stop running workers gracefully'
  task :stop do
    on roles(fetch(:sidekiq_systemd_role)) do
      sudo :systemctl, 'stop', 'sidekiq-*'
    end
  end

  desc 'Start workers'
  task :start do
    on roles(fetch(:sidekiq_systemd_role)) do
      sudo :systemctl, 'start', 'sidekiq-*', '--all'
    end
  end

  desc 'Restart workers'
  task :restart do
    on roles(fetch(:sidekiq_systemd_role)) do
      sudo :systemctl, 'restart', 'sidekiq-*', raise_on_non_zero_exit: false
    end
  end
end
