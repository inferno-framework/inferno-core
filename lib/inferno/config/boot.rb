ENV['APP_ENV'] ||= 'development'

root_path = File.absolute_path(File.join(__dir__, '..', '..', '..'))

Dotenv.load(File.join(root_path, '.env'), File.join(root_path, ".env.#{ENV['APP_ENV']}"))
