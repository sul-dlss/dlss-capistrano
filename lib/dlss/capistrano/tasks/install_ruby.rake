# frozen_string_literal: true

namespace :dlss do
  namespace :ruby do
    desc 'Install a specific Ruby version using RVM and run bundle install'
    task :install, :version do |_task, args|
      on roles(:app) do
        ruby_version = args[:version]

        if ruby_version.nil? || ruby_version.empty?
          error <<~ERROR
            Ruby version is required.

            Usage examples:
              cap stage dlss:ruby:install[ruby-3.1.0]           # Basic usage
              cap stage "dlss:ruby:install[ruby-3.1.0]"         # Quoted (recommended for zsh)
              RUBY_VERSION=ruby-3.1.0 cap stage dlss:ruby:install_with_env
          ERROR
          exit 1
        end

        info "Installing Ruby #{ruby_version} using RVM..."

        # Check if RVM is installed
        rvm_installed = test('which rvm') || test('[ -s "$HOME/.rvm/scripts/rvm" ]') || test('command -v rvm')

        unless rvm_installed
          error <<~ERROR
            RVM is not installed on the remote server.

            To install RVM first, run:
              \\curl -sSL https://get.rvm.io | bash -s stable

            Then logout and login again, or source the RVM script manually.
          ERROR
          exit 1
        end

        # Try to source RVM if it exists
        if test('[ -s "$HOME/.rvm/scripts/rvm" ]')
          execute 'source ~/.rvm/scripts/rvm'
        elsif test('[ -s "/etc/profile.d/rvm.sh" ]')
          execute 'source /etc/profile.d/rvm.sh'
        end

        # Install the Ruby version
        info "Installing Ruby #{ruby_version}..."
        execute "rvm install #{ruby_version}"

        info "Setting Ruby #{ruby_version} as current..."
        execute "rvm use #{ruby_version}"

        # Use Capistrano's bundler task for bundle install with fallback
        info 'Running bundle install using Capistrano bundler task...'
        begin
          invoke! 'bundler:install'
          info "Ruby #{ruby_version} installed successfully and bundle install completed!"
        rescue NameError => e
          warn "Bundler task not available (#{e.message}), trying manual bundle install..."
          # Fallback to manual bundle install in current directory
          if test("[ -f #{current_path}/Gemfile ]")
            within current_path do
              execute 'bundle install'
              info "Ruby #{ruby_version} installed successfully and bundle install completed!"
            end
          else
            error "Could not find Gemfile in #{current_path}. Please check your deployment configuration."
            exit 1
          end
        end
      end
    end

    desc 'Install Ruby version from environment variable RUBY_VERSION'
    task :install_with_env do
      ruby_version = ENV.fetch('RUBY_VERSION', nil)
      if ruby_version.nil? || ruby_version.empty?
        error 'RUBY_VERSION environment variable is required. Usage: RUBY_VERSION=ruby-3.1.0 cap stage ruby:install_with_env'
        exit 1
      end
      invoke 'ruby:install', ruby_version
    end
  end
end
