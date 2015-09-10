require 'pry-byebug'
require 'sinatra/base'
require 'digest/sha2'
require 'mysql2-cs-bind'
require 'rack-flash'
require 'json'
require 'csv'

def users_from_tsv
  CSV.read("../../sql/dummy_users.tsv", "r", col_sep: "\t").map do |row|
    { user_id: row[0],
      login: row[1],
      password_hash: Digest::SHA256.hexdigest("#{row[2]}:#{row[3]}"),
      salt: row[3]
    }
  end
end

module Isucon4
  class App < Sinatra::Base
    use Rack::Session::Cookie, secret: ENV['ISU4_SESSION_SECRET'] || 'shirokane'
    use Rack::Flash
    set :public_folder, File.expand_path('../../public', __FILE__)

    configure do
      set :memory, { users: users_from_tsv, logs: [] }
    end

    helpers do
      def config
        @config ||= {
          user_lock_threshold: (ENV['ISU4_USER_LOCK_THRESHOLD'] || 3).to_i,
          ip_ban_threshold: (ENV['ISU4_IP_BAN_THRESHOLD'] || 10).to_i,
        }
      end

      def db
        Thread.current[:isu4_db] ||= Mysql2::Client.new(
          host: ENV['ISU4_DB_HOST'] || 'localhost',
          port: ENV['ISU4_DB_PORT'] ? ENV['ISU4_DB_PORT'].to_i : nil,
          username: ENV['ISU4_DB_USER'] || 'root',
          password: ENV['ISU4_DB_PASSWORD'],
          database: ENV['ISU4_DB_NAME'] || 'isu4_qualifier',
          reconnect: true,
        )
      end

      def memory
        settings.memory
      end

      def calculate_password_hash(password, salt)
        Digest::SHA256.hexdigest "#{password}:#{salt}"
      end

      def login_log(succeeded, login, user_id = nil)
        memory[:logs] << { created_at: Time.now,
                user_id: user_id,
                login: login,
                ip: request.ip,
                succeeded: succeeded
        }
      end

      def user_locked?(user)
        return nil unless user
        filtered_logs = memory[:logs].select { |log| log[:user_id] == user[:user_id] }
        count = 0
        filtered_logs.reverse.each do |log|
          break if log.last
          count += 1
        end

        config[:user_lock_threshold] <= count
      end

      def ip_banned?
        filtered_logs = memory[:logs].select { |log| log[:ip] == request.ip }
        count = 0
        filtered_logs.reverse.each do |log|
          break if log.last
          count += 1
        end

        config[:ip_ban_threshold] <= count
      end

      def attempt_login(login, password)
        user = memory[:users].find { |u| u[:login] == login }

        if ip_banned?
          login_log(false, login, user ? user[:user_id] : nil)
          return [nil, :banned]
        end

        if user_locked?(user)
          login_log(false, login, user[:user_id])
          return [nil, :locked]
        end

        if user && calculate_password_hash(password, user[:salt]) == user[:password_hash]
          login_log(true, login, user[:user_id])
          [user, nil]
        elsif user
          login_log(false, login, user[:user_id])
          [nil, :wrong_password]
        else
          login_log(false, login)
          [nil, :wrong_login]
        end
      end

      def current_user
        return @current_user if @current_user
        return nil unless session[:user_id]

        @current_user = memory[:users].find { |u| u[:user_id].to_i == session[:user_id].to_i }
        unless @current_user
          session[:user_id] = nil
          return nil
        end

        @current_user
      end

      def last_login
        return nil unless current_user

        memory[:logs].select { |l| (l[:user_id].to_i == current_user[:user_id].to_i) && l[:succeeded] }.last
      end

      def banned_ips
        ips = []
        threshold = config[:ip_ban_threshold]

        memory[:logs].group_by { |l| l[:ip] }.each do |ip, logs|
          count = 0
          logs.reverse.each { |l| l[:succeeded] ? (c += 1) : break }

          ips << ip if threshold <= count
        end

        ips
      end

      def locked_users
        user_ids = []
        threshold = config[:user_lock_threshold]

        memory[:logs].group_by { |l| l[:user_id] }.each do |user_id, logs|
          count = 0
          logs.reverse.each { |l| l[:succeeded] ? (c += 1) : break }

          if threshold <= count
            user_ids << row['login']
          end
        end

        user_ids
      end
    end

    get '/' do
      erb :index, layout: :base
    end

    post '/login' do
      user, err = attempt_login(params[:login], params[:password])

      if user
        session[:user_id] = user[:user_id]
        redirect '/mypage'
      else
        case err
        when :locked
          flash[:notice] = "This account is locked."
        when :banned
          flash[:notice] = "You're banned."
        else
          flash[:notice] = "Wrong username or password"
        end
        redirect '/'
      end
    end

    get '/mypage' do
      unless current_user
        flash[:notice] = "You must be logged in"
        redirect '/'
      end
      erb :mypage, layout: :base
    end

    get '/report' do
      content_type :json
      {
        banned_ips: banned_ips,
        locked_users: locked_users,
      }.to_json
    end
  end
end
