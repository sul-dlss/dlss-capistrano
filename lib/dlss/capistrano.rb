require 'capistrano/one_time_key'
require 'capistrano/shared_configs'

Dir.glob("#{__dir__}/capistrano/tasks/*.rake").each { |r| import r }
Dir.glob("#{__dir__}/capistrano/tasks/setup/*.rake").each { |r| import r }
