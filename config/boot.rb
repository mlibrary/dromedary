ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'pathname'
require 'tmpdir' # otherwise Dir.tmpdir fails. Really, ruby? C'mon!
