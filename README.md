# dlss-capistrano

[![Gem Version](https://badge.fury.io/rb/dlss-capistrano.svg)](https://badge.fury.io/rb/dlss-capistrano)

This gem provides Capistrano deployment tasks used by Stanford Libraries' Digital Library Systems and Services group.

## Necessary Setup

To start, we recommend an SSH configuration like the one described in the [DeveloperPlaybook](https://github.com/sul-dlss/DeveloperPlaybook/blob/main/best-practices/ssh_configuration.md), since it has sensible defaults for Kerberos authentication and multi-factor authentication (using `ProxyJump` and `ControlMaster`, etc.).

To get `dlss-capistrano` tasks running via an existing SSH control master socket, you need to opt-in by setting the environment variable `USE_CAPISTRANO_CONTROLMASTER=true` (in e.g. your `~/.zshenv` file or similar for your particular shell).

If your SSH client configuration (`~/.ssh/config`) uses values other than the defaults for `CONTROLMASTER_HOST` (which maps to the `ProxyJump` directive, and defaults to `dlss-jump`) or `CONTROLMASTER_SOCKET` (which maps to the `ControlPath` directive, and defaults to `~/.ssh/%r@%h:%p`), you'll want to set these environment variables locally to the values you use (in e.g. your `~/.zshenv` file or similar for your particular shell). Otherwise, the gem will fail to connect to the appropriate jump host and/or won't be able to properly check the status of the control master process.

## Included Tasks

### Remote Execution

Sometimes you want to execute a command on all boxes in a given environment, and dlss-capistrano's got your back:

```shell
$ cap qa remote_execute["ps -ef | grep rolling | grep -v grep"]
00:00 remote_execute
      ps -ef | grep rolling | grep -v grep
      ps -ef | grep rolling | grep -v grep
      dor-indexing-app-qa-a.stanford.edu:
dor_ind+  9159     1 20 Feb18 ?        14:15:03 rolling index
      dor-indexing-app-qa-b.stanford.edu:
dor_ind+ 29689     1 20 Feb18 ?        14:24:53 rolling index
```

### Sidekiq symlink

Every time the version of Sidekiq or Ruby changes, a corresponding Puppet PR must be made in order to update the XSendFilePath that allows Apache to access the bundled Sidekiq gem's assets. dlss-capistrano provides a hook to create a symlink to the bundled Sidekiq to avoid having to do this:

```ruby
set :bundled_sidekiq_symlink, true # false is the default value
set :bundled_sidekiq_roles, [:app] # this is the default value
```

Set this in `config/deploy.rb` to automate the symlink creation, and then use `XSendFilePath /path/to/my/app/shared/bundled_sidekiq/web/assets` in Apache configuration (in Puppet).

### Status checking

**NOTE**: Requires that `curl` is installed on each server host the check is run on.

Use `cap ENV check_status` to hit the (_e.g._, [okcomputer](https://github.com/sportngin/okcomputer)-based) status endpoint of your application. This is especially valuable with hosts that cannot be directly checked due to firewall rules.

By default, these checks run against all nodes with the `:web` role and hit the `/status/all` endpoint. These can be configured in `config/deploy.rb` (or `config/deploy/{ENV}.rb` if you need environment-specific variation):

```ruby
set :check_status_roles, [:my_status_check_web_role]
set :check_status_path, '/my/status/check/endpoint'
```

### Update global strscan gem

This insures the global version of strscan matches the version specified in the bundle.

To skip this step provide `SKIP_UPDATE_STRSCAN=1`

### SSH

`cap ENV ssh` establishes an SSH connection to the host running in `ENV` environment, and changes into the current deployment directory

### SSH Connection Checking

`cap ENV ssh_check` establishes an SSH connection to all app servers running in `ENV` environment and prints environment information to confirm the connection was made. This is used by [sdr-deploy](https://github.com/sul-dlss-labs/sdr-deploy/) to check SSH connections can be made in bulk before proceeding with a mass deploy.

### Display Revision (and branches)

`cap ENV deployed_branch` displays the currently deployed revision (commit ID) and any branches containing the revision for each server in `ENV`.

### Sidekiq via systemd

`cap ENV sidekiq_systemd:{quiet,stop,start,restart}`: quiets, stops, starts, restarts Sidekiq via systemd.

These tasks are intended to replace those provided by `capistrano-sidekiq` gem, which has assumptions about systemd that do not apply to our deployed environments.

### Sneakers via systemd

`cap ENV sneakers_systemd:{stop,start,restart}`: stops, starts, restarts Sneakers via systemd.

### SolidQueue via systemd

`cap ENV solid_queue_systemd:{stop,start,restart}`: stops, starts, restarts SolidQueue via systemd.

### Racecar via systemd

`cap ENV racecar_systemd:{stop,start,restart}`: stops, starts, restarts Racecar via systemd.

#### Capistrano role

The sidekiq_systemd tasks assume a Capistrano role of `:app`. If your application uses a different Capistrano role for hosts that run Sidekiq workers, you can configure this in `config/deploy.rb`, _e.g._:

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

## Releasing

To release a new version:

1. Update the version number in `dlss-capistrano.gemspec` and commit.
2. `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the .gem file to rubygems.org.

## Copyright

Copyright (c) 2020 Stanford University. See LICENSE for details.
