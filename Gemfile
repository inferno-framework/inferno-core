source 'https://rubygems.org'

ruby '2.7.3'

gemspec

# To use these test kits, uncomment these lines, run `bundle update`, and
# uncomment the require at the top of
# `dev_suites/dev_demo_ig_stu1/demo_suite.rb`.
# gem 'g10_certification_test_kit',
#     git: 'https://github.com/inferno-framework/g10-certification-test-kit.git',
#     branch: 'main'
# gem 'smart_app_launch_test_kit',
#     git: 'https://github.com/inferno-framework/smart-app-launch-test-kit.git',
#     branch: 'main'
# gem 'us_core_test_kit',
#     git: 'https://github.com/inferno-framework/us-core-test-kit.git',
#     branch: 'main'

group :development, :test do
  gem 'pry'
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
