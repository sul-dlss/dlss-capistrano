# Capistrano plugin hook to set default values
namespace :load do
  task :defaults do
    set :bundled_sidekiq_symlink, fetch(:bundled_sidekiq_symlink, false)
    set :bundled_sidekiq_roles, fetch(:bundled_sidekiq_roles, [:app])
  end
end

# Integrate sidekiq-bundle hook into Capistrano
namespace :deploy do
  before :starting, :add_bundled_sidekiq_hook do
    invoke 'bundled_sidekiq:add_hook' if fetch(:bundled_sidekiq_symlink)
  end
end

namespace :bundled_sidekiq do
  # NOTE: no `desc` here to avoid publishing this task in the `cap -T` list
  task :add_hook do
    after 'bundler:install', 'bundled_sidekiq:symlink'
  end

  # NOTE: no `desc` here to avoid publishing this task in the `cap -T` list
  task :symlink do
    on roles(fetch(:bundled_sidekiq_roles)) do
      within release_path do
        bundled_sidekiq_path = capture(:bundle, :info, '--path', :sidekiq)
        execute(:ln, '-sf', bundled_sidekiq_path, "#{shared_path}/bundled_sidekiq")
      end
    end
  end
end
