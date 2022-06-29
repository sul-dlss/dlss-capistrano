desc "ssh to the current directory on the server"
task :update_global_strscan do
  on roles(:app) do |host|
    strscan_version = within release_path do
      capture(:bundle, 'exec', 'ruby', '-e', '"puts Gem::Specification.find_by_name(\'strscan\').version"', ' || true')
    end

    if strscan_version.empty?
      warn 'strscan is not installed'
    else
      execute "gem install strscan --silent --no-document -v #{strscan_version}"
    end
  end
end

if Rake::Task.task_defined? :'passenger:restart'
  before :'passenger:restart', :update_global_strscan unless ENV['SKIP_UPDATE_STRSCAN']
end
