desc "update the strscan default gem"
task :update_global_strscan do
  on roles(:app) do |host|
    strscan_version = within release_path do
      capture(:bundle, 'exec', 'ruby', '-e', '"puts Gem::Specification.find_by_name(\'strscan\').version"', ' || true')
    end

    next warn 'strscan is not installed' if strscan_version.empty?

    begin
      Gem::Version.new(strscan_version)
    rescue ArgumentError
      next warn "skipping, could not install strscan due to an unrelated error: #{strscan_version}"
    end

    execute "gem install strscan --silent --no-document -v #{strscan_version}"
  end
end

if Rake::Task.task_defined?(:'passenger:restart')
  before :'passenger:restart', :update_global_strscan unless ENV['SKIP_UPDATE_STRSCAN']
end
