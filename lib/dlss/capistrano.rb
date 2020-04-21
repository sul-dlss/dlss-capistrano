require 'capistrano/one_time_key'
require 'capistrano/bundle_audit'
require 'capistrano/shared_configs'

load File.expand_path('../capistrano/tasks/bundle_config.rake', __FILE__)
load File.expand_path('../capistrano/tasks/sidekiq_systemd.rake', __FILE__)
load File.expand_path('../capistrano/tasks/ssh.rake', __FILE__)
