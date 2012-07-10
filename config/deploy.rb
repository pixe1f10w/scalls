#$:.unshift(File.expand_path('./lib', ENV['rvm_path']))

require 'rvm/capistrano'

set :rvm_ruby_string, '1.9.3'
set :rvm_type, :system

require 'bundler/capistrano'

set :application, "calls"
set :repository,  "git@github.com:pixe1f10w/scalls.git"

set :scm, :git

set :use_sudo, false
set ( :run_method ) { use_sudo ? :sudo : :run }

default_run_options[ :pty ] = true

set :user, 'iceman'
set :group, 'adm'
set :runner, user

set :domain, 'admin.alfa.core'
set :host, "#{user}@#{domain}"

role :web, host                          # Your HTTP server, Apache/etc
role :app, host                          # This may be the same as your `Web` server

set :rails_env, :production

set :deploy_to, "/usr/admin/#{application}"
set :unicorn_conf, "#{deploy_to}/current/config/unicorn.rb"
set :unicorn_pid, "#{deploy_to}/shared/pids/unicorn.pid"

namespace :deploy do
    task :restart do
        run "if [ -f #{unicorn_pid} ]; then kill -USR2 `cat #{unicorn_pid}`; else cd #{deploy_to}/current && bundle exec unicorn -c #{unicorn_conf} -E #{rails_env} -D; fi"
    end

    task :start do
        run "cd #{deploy_to}/current && bundle exec unicorn -c #{unicorn_conf} -E #{rails_env} -D"
    end

    task :stop do
        run "if [ -f #{unicorn_pid} ]; then kill -QUIT `cat #{unicorn_pid}`; fi"
    end
end

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"
