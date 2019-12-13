require "ettin"
require_relative '../lib/med_installer/logger'

module Dromedary
  class << self
    def config
      return @config unless @config.nil?
      env = if defined? Rails
              Rails.env
            elsif %w[production development test].include? ENV['RAILS_ENV']
              ENV['RAILS_ENV']
            else
              "development"
            end
      @config = Ettin.for(Ettin.settings_files(Pathname.new(__dir__), env))
    end


    def hyp_to_bibid
      target = Pathname.new(AnnoyingUtilities.data_dir) + 'hyp_to_bibid.json'
      raise Errno::ENOENT.new("Can't find #{target}") unless target.exist?
      @hyp_to_bibid ||= JSON.load(File.open(target))
    end
  end

  # eager load
  self.config
end
