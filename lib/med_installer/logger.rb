require 'semantic_logger'

module MedInstaller


  module Logger

    class MEDFormatter < SemanticLogger::Formatters::Color
      def process_info
        nil
      end
    end


    Formatter = MEDFormatter.new(time_format: "%Y-%m-%d:%H:%M:%S")
    SemanticLogger.add_appender(io: STDERR, level: :info, formatter: Formatter)
    LOGGER = SemanticLogger['Dromedary']

    def logger
      if defined? Rails
        Rails.application.config.rails_semantic_logger
      else
        LOGGER
      end
    end
  end
end
