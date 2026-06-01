require "semantic_logger"

module MedInstaller
# Logging mixin for +MedInstaller+ CLI commands and utilities.
#
# Including or extending this module gives access to a {#logger} method that
# returns +Rails.logger+ inside a Rails app or the module-level
# +SemanticLogger+ instance (+LOGGER+) outside of it.
#
# A custom {MEDFormatter} suppresses the process-info field so logs are
# clean when running standalone CLI commands.
module Logger
  # SemanticLogger formatter that suppresses the process-info prefix.
  class MEDFormatter < SemanticLogger::Formatters::Color
    # @return [nil] suppresses process info from log lines
    def process_info
      nil
    end
  end

  Formatter = MEDFormatter.new(time_format: "%Y-%m-%d:%H:%M:%S")
  SemanticLogger.add_appender(io: $stderr, level: :info, formatter: Formatter)
  LOGGER = SemanticLogger["Dromedary"]

  # Returns the appropriate logger for the current environment.
  # @return [Rails::Logger, SemanticLogger::Logger] Rails logger inside Rails; LOGGER otherwise
  def logger
      if defined? Rails
        Rails.logger
      else
        LOGGER
      end
    end
  end
end
