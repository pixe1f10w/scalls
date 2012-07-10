$LOAD_PATH << "#{File.dirname __FILE__}"

require 'bundler/setup'

require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/memcache'
require 'sinatra/diskcache'

require 'date'
require 'pg'
require 'spreadsheet'

require 'sprockets'
require 'sprockets-sass'
require 'sprockets-helpers'

require 'dalli'
require 'rack/cache'

require 'haml'
require 'sass'
#require 'compass'

#require 'uglifier'
#require 'yui/compressor'

require 'helpers'
require 'application'

app_settings = Calls::Application.get_settings

use Rack::Cache,
    :metastore => "memcached://#{app_settings.memcache_server}/meta",
    :entitystore => "memcached://#{app_settings.memcache_server}/entity"

map '/assets' do
    env = Sprockets::Environment.new
    env.append_path File.join app_settings.root, 'assets', 'javascripts'
    env.append_path File.join app_settings.root, 'assets', 'stylesheets'
    env.append_path File.join app_settings.root, 'assets', 'images'

    Sprockets::Helpers.configure do |cfg|
        cfg.environment = env
        cfg.prefix = '/assets'
        cfg.digest = false
    end

#    env.js_compressor = Uglifier.new :copyright => false
#    env.css_compressor = YUI::CssCompressor.new

    run env
end

map '/' do
    run Calls::Application
end
