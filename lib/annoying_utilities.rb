require 'pathname'
require 'erb'
require 'yaml'
require 'json'
require 'uri'

module AnnoyingUtilities

  CONFIG_DIR = Pathname(__dir__).realdirpath.parent + 'config'

  extend self

  def blacklight_solr_url
    env       = ENV['RAILS_ENVIRONMENT'] || 'development'
    @solr_url ||= load_config_file('blacklight.yml')[env]['url']
  end

  def blacklight_config_file
    load_config_file('blacklight.yml')
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
  def target_directories(datadir, datatype, dirname = [A - Z])
    typedir = Pathname(datadir) + datatype
    regexp  = Regexp.new "\\/#{dirname}.*\\Z", 'x'
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
