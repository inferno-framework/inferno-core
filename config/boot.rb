ENV['APP_ENV'] ||= 'development'

require 'bundler'
Bundler.setup(:default, ENV['APP_ENV'])
Bundler.require(:default, ENV['APP_ENV'])

Dotenv.load('.env', ".env.#{ENV['APP_ENV']}")
