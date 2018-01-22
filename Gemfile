source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

#############################################
# Non-default stuff added by the Dromedary team


# Rails and blacklight

gem 'rails', '~> 5.1.4'
gem 'blacklight', "~> 6.1"


# For bin/dromedary
gem 'hanami-cli'
gem 'concurrent-ruby'

# For solr indexing
gem 'simple_solr_client', require: false

# Semantic logging?
gem 'awesome_print'
gem 'semantic_logger'

# Use pry for the console
group :development, :test do
  gem 'pry-rails'

  #Faster boot times

  gem 'listen',   require: false
  unless defined? JRUBY_VERSION
    gem 'pry-byebug'
  end

end

# Use Puma as the app server
gem 'puma', '~> 3.7'

# Coverage and style
group :development, :test do
  gem 'rubocop', require: false
end

# Debugging
group :development, :test do
  # gem "better_errors"
  # gem "binding_of_caller"
end


#############################################

# Databases

if defined? JRUBY_VERSION
  gem 'jdbc-sqlite3'
  gem 'jdbc-mysql'
else
  gem 'sqlite3'
  gem 'mysql2', require: false
end

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
end


group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem "simplecov", require: false
  gem "factory_bot_rails", "~> 4.0"
end


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'rsolr', '>= 1.0'
gem 'jquery-rails'
