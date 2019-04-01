# dlss-capistrano

[![Gem Version](https://badge.fury.io/rb/dlss-capistrano.svg)](https://badge.fury.io/rb/dlss-capistrano)

This gem contains classes that deal with the Capistrano deployment of SUL DLSS Ruby projects.

## Capfile assumptions

This gem makes the following assumptions about your Ruby project

- You are using Capistrano 3+
- You use git for source control
- The server you deploy to uses rvm, it is installed systemwide, and is the default system ruby
- You do not have an .rvmrc checked into git (should be in your .gitignore)
- You will not use rvm gemsets on the server you deploy to
- Bundler will install specified gems into {your_project_home}/shared/bundle directory
- Will deploy from the master branch, unless you set :branch to another branch or tag


== Copyright

Copyright (c) 2015 Stanford University Library. See LICENSE for details.
