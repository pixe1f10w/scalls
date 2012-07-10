$:.unshift( File.expand_path( './lib', ENV[ 'rvm_path' ] ) )
require 'rvm/capistrano'

set :rvm_ruby_string, '1.9.3'
set :rvm_type, :user

require 'bundler/capistrano'

set :application, 'calls'
set :deploy_to, "/usr/admin/#{application}"
set :unicorn_conf, "#{deploy_to}/current/config/unicorn.rb"
set :unicorn_pid, "#{deploy_to}/shared/pids/unicorn.pid"

set :domain, 'admin.alfa.core'

set :user, 'iceman'
set :group, user
set :runner, user

set :use_sudo, false
set (:run_method) { use_sudo ? :sudo : :run }

default_run_option[ :pty ] = true

set :host, "#{user}@#{domain}"
set :web, host
set :app, host

set :rails_env, :production

set :scm, :git
set :repository, 'git@github.com:pixe1f10w/scalls.git'
set :branch, 'master'
set :git_shallow_clone, 1

role :web, domain
role :app, domain
#role :db, domain, primary => true

set :deploy_via, :remote_cache

namespace :deploy do
    task :start {}
    tast :stop {}

