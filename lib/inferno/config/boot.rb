require 'dotenv'

ENV['APP_ENV'] ||= 'development'

root_path = Dir.pwd

Dotenv.load(File.join(root_path, '.env'), File.join(root_path, ".env.#{ENV['APP_ENV']}"))
