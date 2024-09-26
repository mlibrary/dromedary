require "semantic_logger"

module MedInstaller
  module Logger
    class MEDFormatter < SemanticLogger::Formatters::Color
      def process_info
        nil
      end
    end

    SemanticLogger.add_appender(io: $stdout, formatter: :color)
    # Formatter = MEDFormatter.new(time_format: "%Y-%m-%d:%H:%M:%S")
    LOGGER = SemanticLogger["Dromedary"]

    def logger
      if defined? Rails
        Rails.logger
      end
      LOGGER
    end
  end
end
