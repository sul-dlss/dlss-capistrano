require 'capistrano/one_time_key'
require 'capistrano/bundle_audit'
require 'capistrano/shared_configs'
require 'capistrano/rvm'

Dir.glob("#{__dir__}/capistrano/tasks/*.rake").each { |r| import r }
