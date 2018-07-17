require 'pathname'
require 'erb'
require 'yaml'
require 'json'
require 'uri'
require 'med_installer/logger'
require_relative '../config/load_local_config'

module AnnoyingUtilities

  DROMEDARY_ROOT = Pathname(__dir__).parent.realdirpath
  DOT_SOLR       = DROMEDARY_ROOT + '.solr'
  DEFAULT_SOLR   = DROMEDARY_ROOT.parent + 'solr'
  CONFIG_DIR     = DROMEDARY_ROOT + 'config'

  extend MedInstaller::Logger

  extend self

  def data_dir
    Pathname.new(Dromedary.config.data_dir)
  end

  def bibfile_path
    data_dir + 'bib_all.xml'
  end

  def entries_path
    data_dir + 'entries.json.gz'
  end

  def hyp_to_bibid_path
    data_dir + 'hyp_to_bibid.json'
  end

  def dromedary_root
    DROMEDARY_ROOT
  end

  def indexer_dir
    dromedary_root + 'indexer'
  end

  def xslt_dir
    indexer_dir + 'xslt'
  end


  def blacklight_solr_url(env = nil)
    Dromedary.config.blacklight.url
  end


  def blacklight_config_file
    load_config_file('blacklight.yml')
  end


  def solr_port(env = "development")
    url = blacklight_solr_url
    m   = %r{https?://[^/]+?:(\d+)}.match(url.to_s)
    if m
      m[1]
    else
      nil
    end
  end

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

  def solr_core
    uri      = URI(blacklight_solr_url)
    path     = uri.path.split('/')
    corename = path.pop
    uri.path = path.join('/') # go up a level -- we popped off the core name
    solr_url = uri.to_s

    client = SimpleSolrClient::Client.new(solr_url)
    client.core(corename)
  end


  # Load a config file from the Rails config directory
  def load_config_file(config_file)
    filename = find_file(config_file)

    case file_type(filename)
    when :ruby
      eval(File.read(filename))
    when :yaml
      YAML.load(ERB.new(File.read(filename)).result)
    when :json
      JSON.load(File.read(filename))
    end
  end

  # Get a list of data directories from a datadir, a type,
  # and a list of letters
  def target_directories(datadir, datatype, dir_prefix_regexp = '[A - Z]')
    typedir = Pathname(datadir) + datatype
    regexp  = Regexp.new "\\/#{dir_prefix_regexp}.*\\Z", 'x'
    typedir.children.select {|x| x.directory? and regexp.match(x.to_s)}
  end


  private

  def find_file(config_file)
    if File.exist?(CONFIG_DIR + config_file)
      CONFIG_DIR + config_file
    else
      raise "Can't find config file '#{config_file} in #{CONFIG_DIR} or #{INITIALIZER_DIR}"
    end
  end

  def file_type(filename)
    case filename.extname
    when '.rb'
      :ruby
    when '.yaml', '.yml'
      :yaml
    when '.json'
      :json
    else
      raise "Can't figure out file type of #{filename} from the extension"
    end
  end

end
