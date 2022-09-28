require 'dotenv'

ENV['APP_ENV'] ||= 'development'

root_path = Dir.pwd

Dotenv.load(
  File.join(root_path, ".env.#{ENV.fetch('APP_ENV', nil)}.local"),
  File.join(root_path, '.env.local'),
  File.join(root_path, ".env.#{ENV.fetch('APP_ENV', nil)}"),
  File.join(root_path, '.env')
)
