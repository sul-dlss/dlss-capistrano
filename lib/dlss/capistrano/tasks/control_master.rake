# frozen_string_literal: true

require 'open3'

namespace :load do
  task :defaults do
    set :use_controlmaster, ENV.fetch('USE_CAPISTRANO_CONTROLMASTER', false) == 'true'
    set :controlmaster_host, ENV.fetch('CONTROLMASTER_HOST', 'dlss-jump')
    set :controlmaster_socket, ENV.fetch('CONTROLMASTER_SOCKET', "~/.ssh/%r@%h:%p")
  end
end

# Integrate hook into Capistrano
namespace :deploy do
  before :generate_otk, :setup_controlmaster do
    invoke 'controlmaster:setup'
  end
end

namespace :shared_configs do
  before :check, :setup_connection do
    invoke 'controlmaster:setup'
    invoke 'otk:generate'
  end

  before :update, :setup_connection
  before :pull, :setup_connection
  before :symlink, :setup_connection
end

namespace :controlmaster do
  desc 'set up an SSH controlmaster process if missing'
  task :setup do
    next unless fetch(:use_controlmaster)

    if fetch(:log_level) == :debug
      puts "checking if controlmaster process exists (#{fetch(:controlmaster_socket)}) for #{fetch(:controlmaster_host)}"
    end

    status, output = Open3.popen2e(
      "ssh -O check -S #{fetch(:controlmaster_socket)} #{fetch(:controlmaster_host)}"
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
    next unless fetch(:use_controlmaster)

    if fetch(:log_level) == :debug
      puts "creating new controlmaster process for #{fetch(:controlmaster_host)} at #{fetch(:controlmaster_socket)}"
    end

    status, output = Open3.popen2e(
      "ssh -f -N -S #{fetch(:controlmaster_socket)} #{fetch(:controlmaster_host)}"
    ) { |_, outerr, wait_thr| next wait_thr.value, outerr.read }

    if status.success?
      puts 'new controlmaster process created, moving on' if fetch(:log_level) == :debug
      next
    end

    abort "could not create controlmaster process (#{status}): #{output}"
  end
end
