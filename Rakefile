#!/usr/bin/env rake

desc 'Initial setup'
task :setup do
    `bundle`
    puts 'Setup successfully completed.'
end

desc 'Start application'
task :start do
    puts 'Running rackup... See ya on http://localhost:9292'
    `bundle exec rackup`
end

desc 'Remove cache file'
task :cleanup do
    puts 'Wiping diskcache directory entries...'
    `rm -f diskcache/*`
end

task :default => :start
