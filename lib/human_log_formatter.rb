# Custom SemanticLogger formatter that produces a human-readable, coloured log
# output. Formats timestamps, durations, payloads, and exceptions in aligned
# columns. Solr queries receive special pretty-printing — noisy parameters like
# +facet.limit+ are optionally suppressed.
# @note No references found in codebase — verify it is still wired up in the
#   Rails logger configuration.
class HumanLogFormatter < SemanticLogger::Formatters::Color
  include ActionView::Helpers::TextHelper

  DATE_FORMAT = "%Y-%m-%d %T"

  # Assembles the full log line: time, level, duration, name, tags, named_tags,
  # message, code location, payload, and exception.
  # @param log [SemanticLogger::Log] the log record
  # @param logger [SemanticLogger::Logger] the logger instance
  # @return [String] the formatted log line
  def call(log, logger)
    super
    rv = [time, level, duration, name, tags, named_tags, message].join(" ")
    rv << "\n" << code_location if code_location
    rv << "\n" << payload << "\n" if log.payload
    rv << "\n" << exception if log.exception
    rv
  end

  # Formats the log message, with special handling for Solr queries.
  # Solr query/parameter messages are reformatted into an aligned key/value
  # table with empty and noisy values suppressed.
  # @return [String] the formatted message string
  def message
    return log.message unless /(?:Solr query|Solr parameters)/.match?(log.message)
    msg, query = /\s*(.*?){\s*(.*)}/.match(log.message).captures
    return log.message if query.nil?

    rv = [""]
    rv << "     %37s" % "#{color_map.bold}#{msg}#{color_map.clear}"
    query.scan(/\s*"(.*?)"=>(.*?),/).each do |k, v|
      if defined? Rails && Rails.application.config.human_log.shorten_solr_queries
        next if /facet.limit/.match?(k)
      end
      v.strip!
      next if ["nil", "[]"].include? v
      rv << "%40s: %s" % [k, value_wrap(v)]
    end
    if rv.size == 2
      ""
    else
      rv.join("\n")
    end
  rescue NoMethodError => _e
    raise "Nil on #{query}"
  end

  # @return [String, nil] formatted exception class, message, and backtrace, or +nil+
  def exception
    "-- Exception: #{color}#{log.exception.class}: #{log.exception.message}#{color_map.clear}\n#{log.backtrace_to_s}" if log.exception
  end

  # @return [String] timestamp formatted as +YYYY-MM-DD HH:MM:SS+
  def time
    log.time.strftime DATE_FORMAT
  end

  # @return [String, nil] right-aligned duration string (8 chars), or +nil+ if no duration
  def duration
    "%8s" % super if log.duration
  end

  # Returns the first backtrace line that falls within the Rails app root.
  # @return [String, nil] the relevant backtrace line (Rails root stripped), or +nil+
  def code_location
    if log.backtrace.nil?
      nil
    else
      railsroot = /#{Rails.root}/
      bt = log.backtrace
      mystuff = bt.find { |x| x =~ railsroot }
      mystuff&.gsub(Rails.root.to_s, "")
    end
  end

  # Formats the structured payload as an aligned key/value table.
  # @return [String, nil] the formatted payload string, or +nil+ if no payload
  def payload
    p = log.payload
    return unless p

    # if log.backtrace
    #   require 'pry'; binding.pry
    # end
    rv = []
    rv << "     %27s" % "#{color_map.bold}Payload#{color_map.clear}"
    p.keys.sort.each do |k|
      rv << "%30s: %s" % [k, value_wrap(p[k])]
    end
    rv.join("\n")
  end

  # Word-wraps strings longer than 67 characters; passes other values through unchanged.
  # @param val [Object] the value to format
  # @return [String] the (possibly wrapped) value
  def value_wrap(val)
    if val.is_a?(String) && (val.size > 67)
      word_wrap(val, line_width: 67).gsub("\n", "\n#{" " * 24}")
    else
      val
    end
  end
end
