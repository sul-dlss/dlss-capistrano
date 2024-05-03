# frozen_string_literal: true

require 'open3'

CONTROLMASTER_HOST = ENV.fetch('CONTROLMASTER_HOST', 'dlss-jump')
CONTROLMASTER_SOCKET = ENV.fetch('CONTROLMASTER_SOCKET', "~/.ssh/%r@%h:%p")

# Integrate hook into Capistrano
namespace :deploy do
  before :starting, :setup_controlmaster do
    invoke 'controlmaster:setup'
  end
end

namespace :controlmaster do
  desc 'set up an SSH controlmaster process if missing'
  task :setup do
    if fetch(:log_level) == :debug
      puts "checking if controlmaster process exists (#{CONTROLMASTER_SOCKET}) for #{CONTROLMASTER_HOST}"
    end

    status, output = Open3.popen2e(
      "ssh -O check -S #{CONTROLMASTER_SOCKET} #{CONTROLMASTER_HOST}"
    ) { |_, outerr, wait_thr| next wait_thr.value, outerr.read }

    if status.success?
      puts 'controlmaster process exists, nothing to do' if fetch(:log_level) == :debug
      next
    end

    puts "controlmaster process missing (#{status}): #{output}"
    invoke 'controlmaster:start'
  end

  # NOTE: no `desc` here to avoid publishing this task in the `cap -T` list
  task :start do
    if fetch(:log_level) == :debug
      puts "creating new controlmaster process for #{CONTROLMASTER_HOST} at #{CONTROLMASTER_SOCKET}"
    end

    status, output = Open3.popen2e(
      "ssh -f -N -S #{CONTROLMASTER_SOCKET} #{CONTROLMASTER_HOST}"
    ) { |_, outerr, wait_thr| next wait_thr.value, outerr.read }

    if status.success?
      puts 'new controlmaster process created, moving on' if fetch(:log_level) == :debug
      next
    end

    abort "could not create controlmaster process (#{status}): #{output}"
  end
end
