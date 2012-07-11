#!/usr/bin/env ruby
#encoding: utf-8

module Calls
    class Application < Sinatra::Base
        class << self
            def get_settings
                settings
            end
        end

        register Sinatra::ConfigFile
        register Sinatra::MemCache
        register Sinatra::DiskCache
 
        configure do
            # globals
            set :root, "#{File.dirname __FILE__}"
            set :environments, %w{development production}
            disable :raise_errors

            if development?
                enable :show_exceptions
                enable :cache_logging
                enable :diskcache_logging
            else
                disable :diskcache_logging
                disable :cache_logging
            end
            
            # spreadsheet template
            set :xls_template, 'views/detail.tpl'

            
            # templating
            set :haml, { :format => :html5 }
            #set :sass, Compass.sass_engine_options
            #set :public_directory, "#{settings.root}/public"
    
            #Compass.configuration do |cfg|
            #    cfg.project_path = settings.root
            #    cfg.sass_dir = 'views'
            #end

            config_file "#{settings.root}/config.yml"
            set :cache_server, settings.memcache_server
            set :diskcache_path, "#{settings.root}/#{settings.diskcache_path}"
        end
    
        before do
            request.url << '/' if not url =~ /\/$/

            begin
                @dbconn = PGconn.open :dbname => settings.dbname, :user => settings.dbuser, 
                    :host => settings.dbhost, :password => settings.dbpass
            rescue PGError => e
                puts 'database connection error: ' << e.to_s
                exit
            end
        end
    
        get '/' do
            now = Date.now
            m, y = month_s( now.month ), now.year
            redirect "#{request.url}#{y}/#{m}"
        end

        get '/:year/:month/?' do |year, month|
            if year =~ /^\d{2,4}$/ and month =~ /^(0?[1-9]|1[0-2])$/
                year = '20' + year if year.length == 2
                @date = DateTime.new year.to_i, month.to_i
                @month = "#{month_name( month ).capitalize} #{year} г."

                query = 
                    "with monthly_calls( id, dt_start, duration, id_operator, name, group_descr ) as \
                    ( select c.id, c.dt_start, date_part( 'epoch', c.duration ), p.id_operator, o.name, \
                    g.descr from calls c join phones p on p.id = c.id_caller join operators o on \
                    o.id = p.id_operator join groups g on g.id = p.id_group \
                    where cast( dt_start as varchar )like '#{year}-#{month_s month}-%' ) \
                    select g.name, group_descr, overall, connected, effective, \
                    sqrt( ( connected/overall::float ) * ( effective/overall::float ) ) as percentage from \
                    ( select id_operator as id, count(*) as overall from monthly_calls \
                    group by id_operator ) as a join ( select id_operator as id, count( * ) \
                    as connected from monthly_calls where duration > 2 group by id_operator ) \
                    as c on a.id = c.id join ( select id_operator as id, count( * ) as effective \
                    from monthly_calls where duration > 5 group by id_operator ) as e \
                    on a.id = e.id join ( select distinct( name ), id_operator as id, \
                    group_descr from monthly_calls ) as g on g.id = a.id order by group_descr, g.name;"
=begin
            #@list = res.map { |h| h }
            @list = cache "stat-#{year}-#{month_s month}" do
            #    begin
                    res = @dbconn.query query
            #    rescue PGError => e
                    #@error = e.to_s
                    #halt haml :'error'
            #        raise 400, e.to_s
            #    end
            
                res.map { |h| h }
            end
=end
                @list = cache "stat-#{year}-#{month_s month}" do
                    @dbconn.query( query ).map { |h| h }
                end

                haml :'calls'
            else
                redirect "#{request.url}404"
            end
        end

        get '/:year/:month/export/?' do |year, month|
            if year =~ /^\d{2,4}$/ and month =~ /^(0?[1-9]|1[0-2])$/
                year = '20' + year if year.length == 2
                redirect "#{request.url}404" if Date.now <= Date.months_last_day( year.to_i, month.to_i )

                month = month_s month
                query = "select g.descr as gp, name as op, dt_start as dt, id_caller as from, \
                    id_callee as to, cast( date_part( 'epoch', c.duration ) as int ) as dur \
                    from calls c join phones p on p.id = c.id_caller join operators o on \
                    o.id = p.id_operator join groups g on g.id = p.id_group where \
                    cast( dt_start as varchar ) like '#{year}-#{month}-%' and c.duration is not null \
                    order by dt_start;"

=begin
            detail_file = diskcache "detail_#{month}_#{year}.xls" do |file|
                
                begin
                    res = @dbconn.query query
                rescue PGError => e
                    @error = e.to_s
                    halt haml :'error'
                    raise 400, e.to_s
                end

                calls = res.map { |h| h }
    
                begin
                    book = Spreadsheet.open settings.xls_template
                rescue Ole::Storage::FormatError => e
                    @error = e.to_s
                    halt haml :'error'
                    raise 400, e.to_s
                end
=end
                detail_file = diskcache "detail_#{month}_#{year}.xls" do |file|
                    res = @dbconn.query query
                    calls = res.map { |h| h }
                    book = Spreadsheet.open settings.xls_template
        
                    row = 1
                    sheet = book.worksheet 0

                    calls.each do |call|
                        sheet.row( row ).push call[ 'gp' ], call[ 'op' ], call[ 'dt' ], 
                            call[ 'from' ], call[ 'to' ], call[ 'dur' ]
                        row += 1
                    end

                    book.write file
                end

=begin
            puts detail_file
            
            content_type 'application/force-download'
            content_type 'application/octet-stream'
            content_type 'application/download'
=end
                attachment File.basename detail_file
                response.set_cookie 'fileDownload', :value => 'true', :path => '/' 
                File.read detail_file # send_file helper is unusable here because it's nulls cookie
            else
                redirect "#{request.url}404"
            end
        end

=begin
    # styling moved to assets pipeline
    get '/style.css' do
        content_type 'text/css', :charset => 'utf-8'
        sass :style
    end
=end

    # error handlers
        not_found do
            haml :'404'
        end

        error do
            @error = env[ 'sinatra.error' ].message
            haml :'error'
        end
    end
end
