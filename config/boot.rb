ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'pathname'
require 'tmpdir' # otherwise Dir.tmpdir fails. Really, ruby? C'mon!

# Use bootsnap to make booting...er...snappier
# See https://github.com/Shopify/bootsnap/blob/master/README.md

# Bootsnap only runs in development mode
env = ENV['RAILS_ENV'] || "development"

# Name of the directory for storing the cache. This will
# be put inside of Dir.tmpdir / railscache
# Size is on the order of 50MB

dir_for_cached_files = 'dromedary'

if env == "development"
  require 'bootsnap'
  cachedir = Pathname.new(Dir.tmpdir).realdirpath + 'railscache' + dir_for_cached_files 
  cachedir.mkpath
  Bootsnap.setup(
    cache_dir:            cachedir.to_s,         # Path to your cache
    development_mode:     env == 'development', # Current working environment, e.g. RACK_ENV, RAILS_ENV, etc
    load_path_cache:      true,                 # Optimize the LOAD_PATH with a cache
    autoload_paths_cache: true,                 # Optimize ActiveSupport autoloads with cache
    disable_trace:        true,                 # (Alpha) Set `RubyVM::InstructionSequence.compile_option = { trace_instruction: false }`
    compile_cache_iseq:   true,                 # Compile Ruby code into ISeq cache, breaks coverage reporting.
    compile_cache_yaml:   true                  # Compile YAML into a cache
  )

end
