# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = "lyberteam-capistrano-devel"
  s.version     = "3.0.0"

  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Chris Beer","Willy Mene"]
  s.email       = ["cabeer@stanford.edu"]
  s.summary     = "Capistrano recipies for use in SUL/DLSS projects"
  s.description = "Capistrano recipies  to assist with the development, testing, and release of SUL/DLSS Ruby project"

  s.required_rubygems_version = ">= 1.3.6"
  s.required_ruby_version = '>= 1.9.3'

  # All dependencies are runtime dependencies, since this gem's "runtime" is
  # the dependent gem's development-time.
  s.add_dependency "capistrano", "~> 3.0"
  s.add_dependency "capistrano-releaseboard"
  s.add_dependency "capistrano-bundle_audit"
  s.add_dependency "capistrano-one_time_key"

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
end
