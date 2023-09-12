require "ettin"
require_relative "../lib/med_installer/logger"
require_relative "../lib/dromedary/services"
module Dromedary
  class << self
    # For whatever historical reasons, this uses the Ettin gem to load
    # up yaml files. The list of places it looks are:
    #         root/"settings.yml",
    #         root/"settings"/"#{env}.yml",
    #         root/"environments"/"#{env}.yml",
    #         root/"settings.local.yml",
    #         root/"settings"/"#{env}.local.yml",
    #         root/"environments"/"#{env}.local.yml"
    def config
      return @config unless @config.nil?
      env = if defined? Rails
        Rails.env
      elsif %w[production development test].include? ENV["RAILS_ENV"]
        ENV["RAILS_ENV"]
      else
        "development"
      end
      # @config = Ettin.for(Ettin.settings_files(Pathname.new(__dir__), env))
      @config = Dromedary::Services
    end

    def hyp_to_bibid
      target = Dromedary::Services[:data_dir] + "/" + "hyp_to_bibid.json"
      raise Errno::ENOENT.new("Can't find #{target}") unless target.exist?
      @hyp_to_bibid ||= JSON.parse(File.read(target))
    end
  end

  # eager load
  config
end
