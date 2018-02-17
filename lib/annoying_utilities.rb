require 'pathname'
require 'erb'
require 'yaml'
require 'json'
require 'uri'

module AnnoyingUtilities

  CONFIG_DIR = Pathname(__dir__).realdirpath.parent + 'config'

  extend self

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
