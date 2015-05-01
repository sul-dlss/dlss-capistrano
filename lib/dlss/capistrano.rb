ENV['RELEASE_BOARD_URL'] ||= "https://dlss-releases.stanford.edu"

require 'capistrano/one_time_key'
require 'capistrano/releaseboard'
require 'capistrano/bundle_audit'
