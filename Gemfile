source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

#############################################
# Non-default stuff added by the Dromedary team

# For the data installer

gem 'hanami-cli'

# For solr indexing

gem 'simple_solr_client', require: false

# Faster boot times
gem 'bootsnap', require: false

# Semantic logging
gem 'rails_semantic_logger'
gem "awesome_print"

# Use pry for the console
group :development, :test do
  gem 'pry-rails'
  gem 'pry-byebug'
end

# Use Puma as the app server
gem 'puma', '~> 3.7'

# Coverage and style
group :development, :test do
  gem 'rubocop', require: false
end

# Debugging
group :development, :test do
  gem "better_errors"
  gem "binding_of_caller"
end


#############################################

# Rails and blacklight

gem 'rails', '~> 5.1.4'
gem 'blacklight', ">= 6.1"



# Databases
gem 'sqlite3'
gem 'mysql2', require: false

# JS and CSS
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# gem 'turbolinks', '~> 5'
#

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder

gem 'jbuilder', '~> 2.5'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
  gem "rspec-rails", "~> 3.6"
  gem 'rubyzip'
  gem 'nokogiri'
  gem 'yell' # should just switch to using Semantic Log in Dromedary::Entry
end


group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
end

group :test do
  gem "simplecov", require: false
  gem "factory_bot_rails", "~> 4.0"
end


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :development, :test do
  gem 'solr_wrapper', '>= 0.3'
end

gem 'rsolr', '>= 1.0'
gem 'jquery-rails'
