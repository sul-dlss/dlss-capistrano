# Capistrano plugin hook to set default values
namespace :load do
  task :defaults do
    # This is required to opt-in to the validation
    set :validate_ruby_on_deploy, fetch(:validate_ruby_on_deploy, false)
  end
end

# Add ruby validation hook if app has opted in
namespace :deploy do
  before :starting, :setup_validate_ruby_hook do
    invoke 'ruby:add_hook' if fetch(:validate_ruby_on_deploy)
  end
end

# NOTE: the `/bin/bash -lc` syntax below addresses https://github.com/sul-dlss/operations-tasks/issues/2937
namespace :ruby do
  # This adds the validate_deployed_version task, when configured, early in the deployment to avoid
  # cloning/symlinking/etc if we do not want the deploy to continue.
  task :add_hook do
    after 'deploy:updating', 'ruby:validate_deployed_version' unless ENV['SKIP_VALIDATE_RUBY']
    before 'deploy:updating', 'ruby:run_specified_version' # unless ENV['SKIP_VALIDATE_RUBY']
  end

  desc 'Force SSHKIT to use app-specified Ruby version'
  task :run_specified_version do
    app_ruby = Bundler::LockfileParser.new(Bundler.read_file('Gemfile.lock')).ruby_version&.split&.last&.split('p')&.first

    # Make sure capistrano-rvm uses the version of Ruby specified in the Gemfile.lock
    fetch(:rvm_map_bins).each do |command|
      # Remove the earlier rvm prefix (via capistrano-rvm hook)
      SSHKit.config.command_map.prefix[command.to_sym].shift
      # Patc in the rvm prefix corresponding to the version of Ruby specified in Gemfile.lock
      SSHKit.config.command_map.prefix[command.to_sym].unshift("#{fetch(:rvm_path)}/bin/rvm #{app_ruby} do")
    end
  end

  desc 'Validate ruby version'
  task :validate_deployed_version do
    on roles(:all), in: :sequence do |host|
      app_ruby = Bundler::LockfileParser.new(Bundler.read_file('Gemfile.lock')).ruby_version&.split&.last&.split('p')&.first

      default_ruby = capture("/bin/bash -lc 'rvm --color=no list default string'").chomp.chomp.split('-').last
      system_rubies = capture("/bin/bash -lc 'rvm --color=no list rubies'").split.grep(/ruby/).map do |version|
        version.delete_prefix('ruby-')
      end
      passenger_ruby = if capture("/bin/bash -lc 'command -v passenger-config'", raise_on_non_zero_exit: false).empty?
                         ''
                       else
                         capture("/bin/bash -lc 'passenger-config about ruby-command string | grep -i Version'")
                           .match(/Version: ruby (.+?) /)
                           .captures
                           .first
                       end

      info_str = "#{host} - App: #{app_ruby}, Default: #{default_ruby}, Installed: #{system_rubies.join(', ')}"
      info_str += ", Passenger: #{passenger_ruby}" unless passenger_ruby.empty?

      info info_str

      if app_ruby.nil?
        abort 'Ruby version not set in Gemfile.lock and capistrano configured to validate Ruby version, check Gemfile or run bundle install' if app_ruby.nil?
      elsif !passenger_ruby.empty? && !passenger_ruby.include?(app_ruby)
        abort "Cannot deploy because app required ruby #{app_ruby} and Passenger is using #{passenger_ruby}"
      elsif !system_rubies.include?(app_ruby)
        abort "Cannot deploy because app requires ruby #{app_ruby} and it is not installed (#{system_rubies.join(', ')})"
      else
        info "Ruby #{app_ruby} is installed on #{host}."
      end
    end
  end
end
