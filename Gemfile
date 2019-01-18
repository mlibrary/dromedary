source "https://gems.www.lib.umich.edu"
source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

#############################################
# Non-default stuff added by the Dromedary team

# When developing in tandem, a relative path is nice and easy

# gem 'middle_english_dictionary', path: "/Users/dueberb/devel/med/middle_english_dictionary"
gem 'middle_english_dictionary', '~>1.8.0'

# https://nvd.nist.gov/vuln/detail/CVE-2018-16471

gem 'rack', '~>2.0', '>=2.0.6'

# Deal with security alerts
#
# https://nvd.nist.gov/vuln/detail/CVE-2018-16468

gem 'loofah', '~>2.2', '>=2.2.3'

# Force not-using-bundler-2 until deployment gets fixed
gem 'bundler', '~> 1.0'

# Use Ettin for configuration
#
gem 'ettin'

# Rails and blacklight and such

gem 'rails', '~> 5.1.4'

# Security vulnerability CVE-2018-3760
gem 'sprockets', '~>3.7.2'


# They messed with the auto-suggest code, so we're stuck here for a while
gem 'blacklight', "~> 6.15.0"


# For bin/dromedary
gem 'hanami-cli', "0.2.0" # peg it until I we can update to 3.
gem 'rubyzip', "~> 1.2.2"
gem 'nokogiri'


# For truncating html safely (making sure tags are balanced, etc.)
gem "html_truncator", "~>0.2"

# For solr indexing
gem 'simple_solr_client', require: false # only for bin/dromedary stuff
gem 'traject', require: false # only for indexing
# if defined? JRUBY_VERSION
#   gem 'traject-marc4j_reader'
# end

# Building lists of xpaths
gem 'xpath_list', require: false # only for data analysis


# Semantic logging?
gem 'awesome_print'
gem 'semantic_logger'



gem 'lograge'

# Contacts Email
gem 'mail_form', '1.7.0'
gem 'simple_form', '3.5.1'
# Extendable layouts
gem 'nestive', '0.6.0'

# Use pry for the console
group :development, :test do
  gem 'pry-rails'

  #Faster boot times

  gem 'listen',   require: false
  unless defined? JRUBY_VERSION
    gem 'ruby-prof'
    gem 'pry-byebug'
  end

  gem 'rubocop', require: false
  # Use Puma as the app server
  gem 'puma', '~> 3.7'
end


#############################################

# Databases

if defined? JRUBY_VERSION
  gem 'jdbc-sqlite3'
  gem 'jdbc-mysql'
else
  gem 'sqlite3'
  # AR won't work with the latest mysql2, apparently
  # See https://stackoverflow.com/questions/49407254/gemloaderror-cant-activate-mysql2-0-5-0-3-18-already-activated-mysq
  gem 'mysql2', '< 0.5.0', require: false
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
  # gem 'capybara', '~> 2.13' # no longer deploying like this.
  gem 'selenium-webdriver'
  gem "rspec-rails", "~> 3.6"
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
