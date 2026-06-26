require "pathname"
require "erb"
require "yaml"
require "json"
require "uri"
require "med_installer/logger"
require_relative "../config/load_local_config"
require "dromedary/services"
require "my_simple_solr_client"

# Utility module providing path helpers, config-file loading, and Solr client
# construction for the Dromedary application.
#
# All methods are available both as module-level functions (via +extend self+) and
# as instance methods when the module is included.
#
# Constants locate key directories relative to the application root so that the
# rest of the codebase does not hard-code absolute paths.
module AnnoyingUtilities
  # @return [Pathname] absolute path to the Dromedary application root
  DROMEDARY_ROOT = Pathname(__dir__).parent.realdirpath

  # @return [Pathname] path to the +.solr+ file that optionally overrides the
  #   default Solr installation directory
  DOT_SOLR = DROMEDARY_ROOT + ".solr"

  # @return [Pathname] default Solr installation directory (sibling of app root)
  #   used when {DOT_SOLR} is absent
  DEFAULT_SOLR = DROMEDARY_ROOT.parent + "solr"

  # @return [Pathname] path to the Rails +config/+ directory
  CONFIG_DIR = DROMEDARY_ROOT + "config"

  extend MedInstaller::Logger

  extend self

  # standard:disable Lint/DuplicateMethods
  # @!attribute [rw] data_dir
  #   Override the data directory used by this module.
  #   When set, callers that resolve data paths can use this value instead of
  #   the service-configured directory.
  #   @return [Pathname, String, nil]
  attr_accessor :data_dir

  # def data_dir=(path)
  #   @data_dir = Pathname.new(path).realpath
  # end
  #
  # def data_dir
  #   @data_dir || live_data_dir
  # end

  # @return [Pathname] path to the XML source directory (from Services[:xml_directory])
  def data_directory
    Pathname.new(Dromedary::Services[:xml_directory])
  end

  # @return [Pathname] path to the build output directory (from Services[:build_directory])
  def build_directory
    Pathname.new(Dromedary::Services[:build_directory])
  end
  # standard:enable  Lint/DuplicateMethods

  # @return [Pathname] path to the Solr data directory (+solr/+ under root_directory)
  def solr_dir
    Dromedary::Services[:root_directory] + "solr"
  end

  # @return [Pathname] path to the flag file whose presence enables maintenance mode
  def maintenance_mode_flag_file
    Dromedary::Services[:tmp_dir] + "MAINTENANCE_MODE_ENABLED"
  end

  # @return [Boolean] true if the maintenance mode flag file exists
  def maintenance_mode_enabled?
    File.exist? maintenance_mode_flag_file
  end

  # @return [Pathname] path to +bib_all.xml+ inside the data directory
  def bibfile_path
    data_directory + "bib_all.xml"
  end

  # @return [Pathname] path to +entries.json.gz+ inside the build directory
  def entries_path
    build_directory + "entries.json.gz"
  end

  # @return [Pathname] the application root directory
  def dromedary_root
    Dromedary::Services[:root_directory]
  end

  # @return [Pathname] path to the +indexer/+ directory under the app root
  def indexer_dir
    dromedary_root + "indexer"
  end

  # @return [Pathname] path to the XSLT directory under +indexer/+
  def xslt_dir
    indexer_dir + "xslt"
  end

  # Returns the Solr URL with embedded basic-auth credentials.
  # The +env+ parameter is accepted for API compatibility but is unused;
  # the URL always comes from Services[:solr_embedded_auth_url].
  # @param env [String, nil] unused — kept for backwards compatibility
  # @return [String] the Solr URL with embedded credentials
  def blacklight_solr_url(env = nil)
    # Dromedary.config.blacklight.url
    Dromedary::Services[:solr_embedded_auth_url]
  end

  # @return [Hash] the parsed blacklight.yml config for the current environment
  # @note No references found in codebase — may be unused.
  def blacklight_config_file
    load_config_file("blacklight.yml")
  end

  # Extracts the port number from the Blacklight Solr URL.
  # @param env [String] unused; kept for API compatibility
  # @return [String, nil] the port as a string, or +nil+ if no port found in the URL
  # @note No references found in codebase — may be unused.
  def solr_port(env = "development")
    url = blacklight_solr_url
    m = %r{https?://[^/]+?:(\d+)}.match(url.to_s)
    if m
      m[1]
    end
  end

  # Resolves the path to the Solr installation root.
  # Reads the path from the +.solr+ file if present; falls back to a sibling
  # +solr/+ directory next to the app root.
  # @return [Pathname] the Solr root directory
  # @raise [RuntimeError] if the resolved directory does not exist
  # @note No references found in codebase — may be unused (Solr now runs in containers).
  def solr_root
    solr_root = if File.exist? DOT_SOLR
      dir = Pathname(File.open(DOT_SOLR).first.chomp)
      logger.info "Solr root from .solr file is #{dir} "
      dir
    else
      logger.warn "Cannot find #{DOT_SOLR}"
      logger.warn "Trying default solr root in parent dir at #{DEFAULT_SOLR}"
      DEFAULT_SOLR
    end

    unless Dir.exist? solr_root
      raise "Directory (#{solr_root}) isn't there"
    end
    solr_root
  end

  # Builds a +MySimpleSolrClient::Core+ connected to the configured collection.
  # Derives the core name and Solr base URL by parsing the auth-embedded Solr URL,
  # then returns a core client pointed at that collection.
  # @return [MySimpleSolrClient::Core] a core client for the configured Solr collection
  def solr_core
    uri = URI(blacklight_solr_url)
    path = uri.path.split("/")
    corename = path.pop
    # _collections = path.pop
    _solr = path.pop
    uri.path = path.join("/") # go up a level -- we popped off the api/c/collection name
    solr_url = uri.to_s

    client = MySimpleSolrClient::Client.new(solr_url)
    client.core(corename)
  end

  # Loads and parses a config file from the Rails +config/+ directory.
  # Supports +.rb+ (eval), +.yaml+/+.yml+ (ERB-interpolated YAML), and +.json+.
  # @param config_file [String] filename relative to +CONFIG_DIR+ (e.g. +"blacklight.yml"+)
  # @return [Object] the parsed config (Hash for YAML/JSON, evaluated result for .rb)
  # @raise [RuntimeError] if the file cannot be found or the type is unrecognised
  def load_config_file(config_file)
    filename = find_file(config_file)

    case file_type(filename)
    when :ruby
      eval(File.read(filename)) # standard:disable Security/Eval
    when :yaml
      YAML.safe_load(ERB.new(File.read(filename)).result, aliases: true)
    when :json
      JSON.parse(File.read(filename))
    end
  end

  # Returns subdirectories of +<datadir>/<datatype>/+ whose names match a
  # letter-prefix regexp (default: A–Z).
  # @param datadir [String, Pathname] root data directory
  # @param datatype [String] subdirectory type name (e.g. +"entries"+)
  # @param dir_prefix_regexp [String] regexp fragment matched against the last path segment
  # @return [Array<Pathname>] matching child directories
  # @note No references found in codebase — may be unused.
  def target_directories(datadir, datatype, dir_prefix_regexp = "[A - Z]")
    typedir = Pathname(datadir) + datatype
    regexp = Regexp.new "\\/#{dir_prefix_regexp}.*\\Z", "x"
    typedir.children.select { |x| x.directory? and regexp.match(x.to_s) }
  end

  private

  # Locates a config file by name inside {CONFIG_DIR}.
  # @param config_file [String] filename to look up (e.g. +"blacklight.yml"+)
  # @return [Pathname] the absolute path to the config file
  # @raise [RuntimeError] if the file is not found in {CONFIG_DIR}
  # @note References +INITIALIZER_DIR+ in the error message but that constant is
  #   never defined — the error text is misleading if the file is absent.
  def find_file(config_file)
    if File.exist?(CONFIG_DIR + config_file)
      CONFIG_DIR + config_file
    else
      raise "Can't find config file '#{config_file} in #{CONFIG_DIR} or #{INITIALIZER_DIR}"
    end
  end

  # Determines the file type from the extension of a Pathname.
  # @param filename [Pathname] the file whose type is to be determined
  # @return [:ruby, :yaml, :json] a symbol representing the parsed format
  # @raise [RuntimeError] if the extension is not +.rb+, +.yaml+, +.yml+, or +.json+
  def file_type(filename)
    case filename.extname
    when ".rb"
      :ruby
    when ".yaml", ".yml"
      :yaml
    when ".json"
      :json
    else
      raise "Can't figure out file type of #{filename} from the extension"
    end
  end
end
