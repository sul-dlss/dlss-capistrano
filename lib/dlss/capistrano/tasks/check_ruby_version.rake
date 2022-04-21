# Note:
# - The '/bin/bash -lc' syntax below is addressing https://github.com/sul-dlss/operations-tasks/issues/2937
namespace :ruby do
  desc 'Retrieve ruby versions'
  task :versions do
    on roles(:all), in: :sequence do |host|
      default_ruby = capture("/bin/bash -lc 'rvm list default string'").chomp.chomp.split('-').last
      system_rubies = capture("/bin/bash -lc 'rvm list rubies'").split.grep(/ruby/).map do |version|
        version.delete_prefix('ruby-')
      end
      info "#{host},#{default_ruby},#{system_rubies.join(',')}"
    end
  end

  desc 'Report ruby versions'
  task :check_version do
    on roles(:all), in: :sequence do |host|
      app_ruby = 'N/A' || Bundler::LockfileParser.new(Bundler.read_file('Gemfile.lock')).ruby_version&.split.last.split('p').first

      default_ruby = capture("/bin/bash -lc 'rvm list default string'").chomp.chomp.split('-').last
      system_rubies = capture("/bin/bash -lc 'rvm list rubies'").split.grep(/ruby/).map do |version|
        version.delete_prefix('ruby-')
      end

      unless app_ruby.nil?
        info "#{host} - App: #{app_ruby}, Default: #{default_ruby}, Installed: #{system_rubies.join(', ')}"
      end
    end
  end

  desc 'Verify ruby version'
  task :verify_version do
    on roles(:all), in: :sequence do |host|
      app_ruby = Bundler::LockfileParser.new(Bundler.read_file('Gemfile.lock')).ruby_version.split.last.split('p').first
      default_ruby = capture("/bin/bash -lc 'rvm list default string'").chomp.chomp.split('-').last
      system_rubies = capture("/bin/bash -lc 'rvm list rubies'").split.grep(/ruby/).map do |version|
        version.delete_prefix('ruby-')
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
