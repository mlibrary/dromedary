require "semantic_logger"

module MedInstaller
  module Logger
    class MEDFormatter < SemanticLogger::Formatters::Color
      def process_info
        nil
      end
    end

    LOGGER = if defined? Rails
               Rails.logger
             else
               SemanticLogger.add_appender(io: $stderr, level: :info, formatter: :logfmt)
               SemanticLogger["MED Indexer"]
             end


    def logger
      LOGGER
    end
  end
end
