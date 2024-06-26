# Setup controlmaster SSH session before generating one-time-key
before 'otk:generate', 'controlmaster:setup'

DOES_NOT_REQUIRE_OTK_LIST = [
  'bundler:map_bins',
  'controlmaster:setup',
  'controlmaster:start',
  'default',
  'deploy:generate_otk',
  'install',
  'load:defaults',
  'otk:generate',
  *Rake.application.stages
].freeze

Rake.application.tasks.each do |task|
  next if DOES_NOT_REQUIRE_OTK_LIST.include?(task.name)

  before task, 'deploy:generate_otk'
end
