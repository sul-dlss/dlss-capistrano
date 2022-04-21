# Capistrano plugin hook to set default values
namespace :load do
  task :defaults do
    set :validate_ruby_on_deploy, fetch(:validate_ruby_on_deploy, false) # This is required to opt-in to the validation
    set :skip_validate_ruby, !!ENV['SKIP_VALIDATE_RUBY']
  end
end

# Integrate sidekiq-bundle hook into Capistrano
namespace :deploy do
  before :starting, :add_validate_ruby_hook do
    invoke 'ruby:add_hook' if fetch(:validate_ruby_on_deploy)
  end
end

# Note:
# - The '/bin/bash -lc' syntax below is addressing https://github.com/sul-dlss/operations-tasks/issues/2937
namespace :ruby do
  desc 'Retrieve the installed versions of ruby'
  task :installed_versions do
    on roles(:all), in: :sequence do |host|
      default_ruby = capture("/bin/bash -lc 'rvm list default string'").chomp.chomp.split('-').last
      system_rubies = capture("/bin/bash -lc 'rvm list rubies'").split.grep(/ruby/).map do |version|
        version.delete_prefix('ruby-')
      end
      info "#{host}: #{default_ruby},#{system_rubies.join(',')}"
    end
  end

  desc 'Report ruby versions'
  task :check_app_version do
    on roles(:all), in: :sequence do |host|
      app_ruby = Bundler::LockfileParser.new(Bundler.read_file('Gemfile.lock')).ruby_version&.split.last.split('p').first || 'N/A'

      default_ruby = capture("/bin/bash -lc 'rvm list default string'").chomp.chomp.split('-').last
      passenger_ruby = capture("/bin/bash -lc 'passenger-config about ruby-command string | grep -i Version'",
                               raise_on_non_zero_exit: false)
      system_rubies = capture("/bin/bash -lc 'rvm list rubies'").split.grep(/ruby/).map do |version|
        version.delete_prefix('ruby-')
      end

      info_str = "#{host} - App: #{app_ruby}, Default: #{default_ruby}, Installed: #{system_rubies.join(', ')}"
      info_str += "\n\tPassenger: #{passenger_ruby}" unless passenger_ruby.empty?

      info info_str
    end
  end

  # This adds the verify_deployed_Version task, when configured, early in the deploymen to avoid
  # cloning/symlinking/etc if we do not want the deploy to continue.
  task :add_hook do
    before 'git:wrapper', 'ruby:verify_deployed_version' unless ENV['SKIP_VALIDATE_RUBY']
  end

  desc 'Verify ruby version'
  task :verify_deployed_version do
    on roles(:all), in: :sequence do |host|
      app_ruby = Bundler::LockfileParser.new(Bundler.read_file('Gemfile.lock')).ruby_version&.split&.last&.split('p')&.first
      passenger_ruby = capture("/bin/bash -lc 'passenger-config about ruby-command string | grep -i Version'",
                               raise_on_non_zero_exit: false)
      default_ruby = capture("/bin/bash -lc 'rvm list default string'").chomp.chomp.split('-').last
      system_rubies = capture("/bin/bash -lc 'rvm list rubies'").split.grep(/ruby/).map do |version|
        version.delete_prefix('ruby-')
      end

      abort 'Ruby version not set in application, check Gemfile' if app_ruby.nil?

      unless passenger_ruby.empty? || passenger_ruby.include?(app_ruby)
        abort "Cannot deploy because app required ruby #{app_ruby} Passenger is configured to use:\n\t#{passenger_ruby}"
      end

      if system_rubies.include?(app_ruby)
        if app_ruby == default_ruby
          info "Ruby #{app_ruby} is default on #{host}."
        else
          abort "Cannot deploy because app requires ruby #{app_ruby} and it is not default (#{system_rubies.join(', ')})"
        end
      else
        abort "Cannot deploy because app requires ruby #{app_ruby} and it is not installed (#{system_rubies.join(', ')})"
      end
    end
  end
end
