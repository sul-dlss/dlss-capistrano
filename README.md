# dlss-capistrano

[![Gem Version](https://badge.fury.io/rb/dlss-capistrano.svg)](https://badge.fury.io/rb/dlss-capistrano)

This gem provides Capistrano deployment tasks used by Stanford Libraries' Digital Library Systems and Services group.

## Included Tasks

### SSH

`cap ENV ssh` establishes an SSH connection to the host running in `ENV` environment, and changes into the current deployment directory

### Sidekiq via systemd

`cap ENV sidekiq_systemd:{quiet,stop,start,restart}`: quiets, stops, starts, restarts Sidekiq via systemd.

These tasks are intended to replace those provided by `capistrano-sidekiq` gem, which has assumptions about systemd that do not apply to our deployed environments.

#### Capistrano role

The sidekiq_systemd tasks assume a Capistrano role of `:app`. If your application uses a different Capistrano role for hosts that run Sidekiq workers, you can configure this in `config/deploy.rb`, *e.g.*:

```ruby
set :sidekiq_systemd_role, :worker
```

#### Deployment hooks

The sidekiq_systemd tasks assume you want to hook them into Capistrano deployment on your own. If you want to use the hooks provided by `dlss-capistrano`, you can opt in via `config/deploy.rb`:

```ruby
set :sidekiq_systemd_use_hooks, true
```

These are the hooks provided if you opt in:

```ruby
after 'deploy:failed', 'sidekiq_systemd:restart'
after 'deploy:published', 'sidekiq_systemd:start'
after 'deploy:starting', 'sidekiq_systemd:quiet'
after 'deploy:updated', 'sidekiq_systemd:stop'
```

## Assumptions

dlss-capistrano makes the following assumptions about your Ruby project

- You are using Capistrano 3+
- You use git for source control
- The server you deploy to uses rvm, it is installed system-wide, and is the default system ruby
- You do not have an .rvmrc checked into git (should be in your .gitignore)
- You will not use rvm gemsets on the server you deploy to
- Bundler will install specified gems into {your_project_home}/shared/bundle directory
- Will deploy from the master branch, unless you set :branch to another branch or tag

## Copyright

Copyright (c) 2020 Stanford University. See LICENSE for details.
