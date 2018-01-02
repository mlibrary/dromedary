ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'pathname'
require 'tmpdir' # otherwise Dir.tmpdir fails. Really, ruby? C'mon!

# Use bootsnap to make booting...er...snappier...under devel and testing
# See https://github.com/Shopify/bootsnap/blob/master/README.md
#
# Example
# > bin/rspec spec/exit_immediately_spec.rb
#
#   Finished in 0.00396 seconds (files took 2.22 seconds to load)
# 1 example, 0 failures
#
# > bin/rspec spec/exit_immediately_spec.rb
#
#   Finished in 0.00198 seconds (files took 0.71378 seconds to load)
# 1 example, 0 failures

# Name of the directory for storing the cache. This will
# be put inside of Dir.tmpdir / railscache
# Size is on the order of 50MB

env = ENV['RAILS_ENV'] || 'development'

parent_dir_for_cached_files = "/tmp/" # Dir.tmpdir
bootstrap_tempdir           = 'dromedary'
cachedir                    = Pathname.new(parent_dir_for_cached_files).realdirpath + 'railscache' + bootstrap_tempdir
use_bootsnap = %w[development test].include?(env) and ENV["CI"] != true


if use_bootsnap
  require 'bootsnap'
  cachedir.mkpath
  Bootsnap.setup(
    cache_dir: cachedir.to_s, # Path to your cache
    development_mode: true, # Current working environment, e.g. RACK_ENV, RAILS_ENV, etc
    load_path_cache: true, # Optimize the LOAD_PATH with a cache
    autoload_paths_cache: true, # Optimize ActiveSupport autoloads with cache
    disable_trace: true, # (Alpha) Set `RubyVM::InstructionSequence.compile_option = { trace_instruction: false }`
    compile_cache_iseq: true, # Compile Ruby code into ISeq cache, breaks coverage reporting.
    compile_cache_yaml: true # Compile YAML into a cache
  )

end
