require "rails_semantic_logger"

module Dromedary
  class AbbreviatedJsonFormat < SemanticLogger::Formatters::Json


    def application
      "MED"
    end

    def name; end

    def host; end

    def duration_ms; end

    def pid; end

    def level_index; end

    def thread_name; end

    def db_runtime; end

    def process_info; end

    def status_message; end

    def params
      super.reject { |k, v| %x(utf8 authenticity_token redirect db_runtime).include? k }
    end
  end
end
