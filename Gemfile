source 'https://rubygems.org'

ruby '3.3.6'

gemspec

# To test with the g10 test kit (this also adds the US Core, SMART, and TLS test
# kits):
# - Uncomment this line (and change test kit gem as necessary):
# gem 'onc_certification_g10_test_kit'

# - Run `bundle`
# - Uncomment (and change as necessary) the require at the top of
# `dev_suites/dev_demo_ig_stu1/demo_suite.rb`.

group :development, :test do
  gem 'debug'
  # Pinned exactly (not `~>`) so a broad `bundle update` can't silently bump
  # the linter and change which rules/autocorrects apply across the repo --
  # bumping these is a deliberate, reviewed decision, not a side effect.
  gem 'rubocop', '1.67.0'
  gem 'rubocop-ast', '1.32.3', require: false
  gem 'rubocop-rake', '0.6.0', require: false
  gem 'rubocop-rspec', '3.1.0', require: false
  gem 'rubocop-sequel', '0.3.4', require: false
end

group :development do
  gem 'yard', '>= 0.9.44'
  gem 'yard-junk'
end

group :test do
  gem 'codecov', '0.5.2'
  gem 'database_cleaner-sequel'
  gem 'factory_bot', '~> 6.1'
  gem 'rack-test'
  # Pinned exactly so a broad `bundle update` can't silently bump the test
  # framework version out from under the suite.
  gem 'rspec', '3.13.0'
  gem 'rspec-core', '3.13.1'
  gem 'rspec-expectations', '3.13.3'
  gem 'rspec-mocks', '3.13.2'
  gem 'rspec-support', '3.13.1'
  gem 'simplecov', '0.21.2', require: false
  gem 'simplecov-cobertura', '~> 3.1'
  gem 'webmock', '~> 3.11'
end
