set :branch,      'origin/master'
set :rails_env,   'production'
set :deploy_to,   '/home/deployer/apps/nembrot'

set :application, 'nembrot'

default_environment['RAILS_ENV'] = 'production'

default_environment['PATH']         = '/usr/local/rvm/gems/ruby-2.0.0-p195@nembrot/bin:/usr/local/rvm/gems/ruby-2.0.0-p195@nembrot/bin:/usr/local/rvm/rubies/ruby-2.0.0-p195/bin:/usr/local/rvm/bin:$PATH'
default_environment['GEM_HOME']     = '/usr/local/rvm/gems/ruby-2.0.0-p195@nembrot'
default_environment['GEM_PATH']     = '/usr/local/rvm/gems/ruby-2.0.0-p195@nembrot:/usr/local/rvm/gems/ruby-2.0.0-p195@nembrot'
default_environment['RUBY_VERSION'] = 'ruby-2.0.0-p195'
