class HumanLogFormatter < SemanticLogger::Formatters::Color
  include ActionView::Helpers::TextHelper

  DATE_FORMAT = "%Y-%m-%d %T"

  def call(log, logger)
    super
    rv = [time, level, duration, name, tags, named_tags, message].join(" ")
    rv << "\n" << code_location if code_location
    rv << "\n" << payload << "\n" if log.payload
    rv << "\n" << exception if log.exception
    rv
  end

  # We can pretty up the solr queries by throwing out everything
  # that isn't set and making a nice display of the rest.
  # If this isn't a solr thing, just return the regular message
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

  def exception
    "-- Exception: #{color}#{log.exception.class}: #{log.exception.message}#{color_map.clear}\n#{log.backtrace_to_s}" if log.exception
  end

  def time
    log.time.strftime DATE_FORMAT
  end

  def duration
    "%8s" % super if log.duration
  end

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

  def value_wrap(val)
    if val.is_a?(String) && (val.size > 67)
      word_wrap(val, line_width: 67).gsub(/\n/, "\n#{" " * 24}")
    else
      val
    end
  end
end
