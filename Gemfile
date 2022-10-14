source 'https://rubygems.org'

ruby '3.1.2'

gemspec

# To test with the g10 test kit (this also adds the US Core, SMART, and TLS test
# kits):
# - Uncomment this line:
gem 'onc_certification_g10_test_kit',
    path: '../onc-certification-g10-test-kit'
gem 'smart_app_launch_test_kit',
    path: '../smart-app-launch-test-kit'
gem 'us_core_test_kit',
    path: '../us-core-test-kit'
gem 'tls_test_kit',
    path: '../tls-test-kit'

# - Run `bundle update`
# - Uncomment the require at the top of
# `dev_suites/dev_demo_ig_stu1/demo_suite.rb`.

group :development, :test do
  gem 'pry'
  gem 'pry-remote'
  gem 'pry-byebug'
  gem 'rubocop', '~> 1.9'
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-sequel', require: false
end

group :development do
  gem 'yard'
  gem 'yard-junk'
end

group :test do
  gem 'codecov'
  gem 'database_cleaner-sequel'
  gem 'rack-test'
  gem 'rspec'
  gem 'simplecov'
  gem 'webmock'
  gem 'factory_bot'
end
