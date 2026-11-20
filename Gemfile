source "https://rubygems.org"

ruby "~> 4.0"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# GitHub Packages requires tokens, even for public repositories; so we use git for now
# source "https://rubygems.pkg.github.com/mlibrary" do
#   gem "middle_english_dictionary", "1.9.1"
# end

gem "pg"
gem "date_named_file"
gem "zinzout"
gem "representable"
gem "multi_json"
gem "solr_cloud-connection", path: "vendor/solr_cloud-connection"

gem "shrine", "~> 3.6"
gem "aws-sdk-s3", "~> 1.160"
gem "content_disposition", "~> 1.0"
gem "uppy-s3_multipart", "~> 1.2"

gem "ttl_memoizeable"

#####################################
# Platform workarounds
###################################

gem "puma"

###############################
# Remaining capped dep
###############################

# Bootstrap 5 support in simple_form landed in 5.2; 4.x had an XSS bug
# (https://github.com/advisories/GHSA-r74q-gxcg-73hx)
gem "simple_form", "~> 5.0"

# Historical note: the CVE floors that used to live here (rack, websocket-extensions,
# kaminari, activesupport, actionpack, actionview, loofah, nokogiri) were all
# satisfied by rails ~> 8.1 and blacklight ~> 9.2 and have been removed.
# Re-check with `bundler-audit` / `bundle exec bundle audit` before adding new ones.

#############################################
# Non-default stuff added by the Dromedary team
#############################################

# When developing in tandem, a relative path is nice and easy

# Use Ettin for configuration and Canister for DI
#
gem "ettin"
gem "canister"

# Rails
#  https://groups.google.com/forum/#!topic/rubyonrails-security/GN7w9fFAQeI)

gem "rails", "~> 8.0", ">= 8.1.0"

gem "sprockets", "~> 4.0"

gem "blacklight", "~> 9.0", ">= 9.2"

# Bootstrap 5 (required by BL9)
gem "bootstrap", "~> 5.0"
gem "autoprefixer-rails"
gem "font-awesome-rails"

# For bin/dromedary
gem "hanami-cli", "0.2.0" # peg it until I we can update to 3.

# For truncating html safely (making sure tags are balanced, etc.)
gem "html_truncator", "~>0.2"

# For solr indexing
gem "simple_solr_client", require: false # only for bin/dromedary stuff
gem "traject", require: false # only for indexing

# Building lists of xpaths
# gem 'xpath_list', git: 'https://github.com/billdueber/xpath_list', require: false # only for data analysis

# Semantic logging?
gem "awesome_print"
gem "semantic_logger"

gem "lograge", ">=0.11.1"

# Contacts Email
gem "mail_form", "~>1.7"

# Use pry for the console
group :development, :test do
  gem "pry-rails"

  # Faster boot times

  gem "listen", require: false
  gem "ruby-prof"
  gem "pry-byebug"
end

#############################################

# Databases
gem "sqlite3"
# AR won't work with the latest mysql2, apparently
# See https://stackoverflow.com/questions/49407254/gemloaderror-cant-activate-mysql2-0-5-0-3-18-already-activated-mysq
#gem "mysql2", "< 0.5.0", require: false

# JS and CSS
gem "sass-rails", "~> 6.0"
gem "uglifier", ">= 1.3.0"
# coffee-rails removed: no Rails 6 support and bibliography.coffee is empty

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# gem 'turbolinks', '~> 5'
#

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder

gem "jbuilder", "~> 2.5"

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

###############################
# Gems for automated indexing #
###############################
gem "prometheus-client", "~> 4.0"
gem "sidekiq", ">= 7.3.3"
gem "okcomputer"

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # gem 'capybara', '~> 2.13' # no longer deploying like this.
  gem "capybara"
  gem "selenium-webdriver"
  gem "rspec-rails", "~> 6.0"
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem "web-console", ">= 3.3.0"
  gem "standard", require: false
end

group :test do
  gem "simplecov", require: false
  gem "factory_bot_rails", "~> 6.0"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw]

gem "rsolr", ">= 1.0"
