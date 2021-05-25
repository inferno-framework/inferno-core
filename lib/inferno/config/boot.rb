ENV['APP_ENV'] ||= 'development'

require 'bundler'
Bundler.setup(:default, ENV['APP_ENV'])
Bundler.require(:default, ENV['APP_ENV'])

root_path = File.absolute_path(File.join(__dir__, '..', '..', '..'))

Dotenv.load(File.join(root_path, '.env'), File.join(root_path, ".env.#{ENV['APP_ENV']}"))
