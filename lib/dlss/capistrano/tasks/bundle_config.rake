# frozen_string_literal: true

# These tasks exist because capistrano-bundler does not yet have a built-in
# mechanism for configuring bundler 2 without deprecation warnings. We can dump
# this if/when https://github.com/capistrano/bundler/issues/115 is resolved.

def default_bundle_path
  Pathname.new("#{shared_path}/bundle")
end

namespace :load do
  task :defaults do
    # This provides opt-in behavior. Do nothing if not requested.
    set :bundler2_config_use_hook, fetch(:bundler2_config_use_hook, false)
    set :bundler2_config_roles, fetch(:bundler2_config_roles, [:app])
    set :bundler2_config_deployment, fetch(:bundler2_config_deployment, true)
    set :bundler2_config_without, fetch(:bundler2_config_without, 'development:test')
    # NOTE: `shared_path` is not defined at this point, so we can't set the default value to `default_bundle_path`
    set :bundler2_config_path, fetch(:bundler2_config_path, nil)
  end
end

# Integrate bundle config hook into Capistrano
namespace :deploy do
  before :starting, :add_bundler2_config_hook do
    invoke 'bundler2:add_hook' if fetch(:bundler2_config_use_hook)
  end
end

namespace :bundler2 do
  # NOTE: no `desc` here to avoid publishing this task in the `cap -T` list
  task :add_hook do
    # Override capistrano-bundler settings
    # HT: https://github.com/capistrano/bundler/issues/115#issuecomment-616570236
    set :bundle_flags, '--quiet' # this unsets --deployment, see details in config_bundler task details
    set :bundle_path, nil
    set :bundle_without, nil

    before 'bundler:install', 'bundler2:config'
  end

  # NOTE: This task lacks a `desc` to avoid publishing it, since we do not
  #       foresee needing to run this task manually. It should run via hook.
  #
  # Configure bundler 2 without using deprecated arguments (overrides capistrano-bundler
  task :config do
    on roles fetch(:bundler2_config_roles) do
      execute "bundle config --local deployment #{fetch(:bundler2_config_deployment)}"
      execute "bundle config --local without '#{fetch(:bundler2_config_without)}'"
      execute "bundle config --local path #{fetch(:bundler2_config_path) || default_bundle_path}"
    end
  end
end
