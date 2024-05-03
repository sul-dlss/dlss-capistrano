desc 'display the deployed branch and commit'
task deployed_branch: 'controlmaster:setup' do
  # see https://github.com/mattbrictson/airbrussh/tree/v1.5.2?tab=readme-ov-file#capistrano-34x
  Airbrussh.configure do |config|
    config.truncate = false
  end

  on roles(:app) do |host|
    within current_path do
      revision = capture :cat, 'REVISION'
      branches = `git branch -r --contains #{revision}`.strip
      info "#{host}: #{revision} (#{branches})"
    end
  end
end
