require 'capistrano/bundle_audit'
require 'capistrano/shared_configs'

# NOTE: This is only here so we can test this task against any host without needing to touch config/deploy/*.rb
#
# Instead of generating a one-time key, add legit gssapi authN via `net-ssh-krb` gem (thanks again, cbeer!)
module Capistrano
  module OneTimeKey
    def self.generate_one_time_key!
    end
  end
end

Dir.glob("#{__dir__}/capistrano/tasks/*.rake").each { |r| import r }
