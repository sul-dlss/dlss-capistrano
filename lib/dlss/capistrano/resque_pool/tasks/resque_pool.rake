# frozen_string_literal: true

# These tasks are a drop-in replacement for capistrano-resque-pool when using
# hot-swappable pools. We replace these tasks because the upstream ones assume a
# pidfile is present, which is not the case with hot-swappable pools.

namespace :load do
  task :defaults do
    # Same capistrano variable used by capistrano-resque-pool for compatibility
    set :resque_server_roles, fetch(:resque_server_roles, [:app])
  end
end

# Integrate hook into Capistrano
namespace :deploy do
  before :starting, :add_resque_pool_hotswap_hook do
    invoke 'resque:pool:add_hook'
  end
end

namespace :resque do
  namespace :pool do
    # Lifted from capistrano-resque-pool
    def rails_env
      fetch(:resque_rails_env) ||
        fetch(:rails_env) ||       # capistrano-rails doesn't automatically set this (yet),
        fetch(:stage)              # so we need to fall back to the stage.
    end

    # NOTE: no `desc` here to avoid publishing this task in the `cap -T` list
    task :add_hook do
      after 'deploy:publishing', 'resque:pool:hot_swap'
    end

    desc 'Swap in a new pool, then shut down the old pool'
    task :hot_swap do
      on roles(fetch(:resque_server_roles)) do
        within current_path do
          execute :bundle, :exec, 'resque-pool', "--daemon --hot-swap --environment #{rails_env}"
        end
      end
    end

    desc 'Gracefully shut down current pool'
    task :stop do
      on roles(fetch(:resque_server_roles)) do
        # This will usually return a single pid, but if you do multiple quick
        # deployments, you may pick up multiple pids here, in which case we only
        # kill the oldest one
        pid = capture(:pgrep, '-f resque-pool-master').split.first

        if test "kill -0 #{pid} > /dev/null 2>&1"
          execute :kill, "-s QUIT #{pid}"
        else
          warn "Process #{pid} is not running"
        end
      end
    end
  end
end
