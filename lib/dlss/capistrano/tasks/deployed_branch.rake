desc 'display the deployed branch and commit'
task :deployed_branch do
  on roles(:app) do |host|
    within current_path do
      revision = capture :cat, 'REVISION'
      branches = `git branch -r --contains #{revision}`.strip
      info "#{host}: #{revision} (#{branches})"
    end
  end
end
