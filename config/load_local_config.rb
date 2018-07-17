require "ettin"
require_relative '../lib/med_installer/logger'

module Dromedary
  class << self
    include MedInstaller::Logger
    def config
      return @config unless @config.nil?
      env = if defined? Rails
              logger.info "Getting env from Rails"
              Rails.env
            elsif %w[production development test].include? ENV['RAILS_ENV']
              logger.info "Getting env environment"
              ENV['RAILS_ENV']
            else
              logger.info "Using default env of 'development'"
              "development"
            end
      logger.info "Working in rails environment '#{env}'"
      @config = Ettin.for(Ettin.settings_files(Pathname.new(__dir__), env))
      logger.info "Finished loading Ettin files"
    end


    def hyp_to_bibid
      target = Pathname.new(Dromedary.config.data_dir) + 'hyp_to_bibid.json'
      @hyp_to_bibid ||= JSON.load(File.open(target))
    end
  end

  # eager load
  self.config
end
