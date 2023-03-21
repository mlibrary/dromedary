require_relative "../load_local_config"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.seconds.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

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

  # env = ENV['RAILS_ENV'] || 'development'
  #
  # parent_dir_for_cached_files = "/tmp/" # Dir.tmpdir
  # bootstrap_tempdir           = 'dromedary'
  # cachedir                    = Pathname.new(parent_dir_for_cached_files).realdirpath + 'railscache' + bootstrap_tempdir
  # use_bootsnap = %w[development test].include?(env) and ENV["CI"] != true
  #
  #
  # if use_bootsnap
  #   require 'bootsnap'
  #   cachedir.mkpath
  #   Bootsnap.setup(
  #       cache_dir: cachedir.to_s, # Path to your cache
  #       development_mode: true, # Current working environment, e.g. RACK_ENV, RAILS_ENV, etc
  #       load_path_cache: true, # Optimize the LOAD_PATH with a cache
  #       autoload_paths_cache: true, # Optimize ActiveSupport autoloads with cache
  #       disable_trace: true, # (Alpha) Set `RubyVM::InstructionSequence.compile_option = { trace_instruction: false }`
  #       compile_cache_iseq: true, # Compile Ruby code into ISeq cache, breaks coverage reporting.
  #       compile_cache_yaml: true # Compile YAML into a cache
  #   )
  # end
end
