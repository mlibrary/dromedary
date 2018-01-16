# encoding: UTF-8
require 'json'
require 'human_log_formatter'


Rails.application.configure do

  # Semantic logging
  # https://rocketjob.github.io/semantic_logger/rails.html
  #

  # Give ourselves a namespace
  config.human_log = ActiveSupport::OrderedOptions.new

  # and log it up
  config.after_initialize do

    ##### Logging options #####


    # --------------------------------------
    # Normal Rails log
    # --------------------------------------

    config.rails_semantic_logger.semantic   = true
    config.rails_semantic_logger.started    = true
    config.rails_semantic_logger.processing = true
    config.rails_semantic_logger.rendered   = true
    config.rails_semantic_logger.quiet_assets = true
    config.rails_semantic_logger.format = :one_line

    # -----------------------------------------
    # HUMAN READABLE LOG CONFIG
    # -----------------------------------------

    config.human_log.human_readable_level = :debug

    # For which level should we go through the work of getting
    # the backtrace? Note: doesn't seem that slow, but can be
    config.human_log.backtrace_level = :debug

    # TODO Reverse these so true == don't log it


    #### Which annoying things to log ###
    #### false means "don't log this"

    config.human_log.log_rack_started = false

    # Log every log entry that has SQL in it
    config.human_log.log_sql false

    # ONLY SQL transaction begin/commit transaction messages
    config.human_log.log_sql_transactions = false

    # Show all the "Rendering..." messages
    config.human_log.log_render_msgs = false

    # There's a path called notifications_number that gets polled every
    # ten seconds or something. False means "I don't want that"
    config.human_log.log_notifications_number = false

    # Show the cancan stuff
    config.human_log.log_cancan = false

    # Show the solr parameters and the solr response time
    config.human_log.log_solr_params = true
    config.human_log.log_solr_times  = true

    # We can make the solr queries go away, or do a bunch of work
    # to make them easier to read
    config.human_log.log_solr_queries     = true
    config.human_log.shorten_solr_queries = true

    # Stupid warning in ActiveFedora::SolrService
    # Fixed in current master, but not in 11.4.0 (current stable)
    config.human_log.log_solr_get_without_rows = false

    # Show the "Looking for <partial_name>"?
    config.human_log.looking_for_partial = false




    #-------------------------------------------------------------------
    ## Leave below this line alone for now ##
    #-------------------------------------------------------------------

    config.semantic_logger.add_appender(file_name: "log/#{Rails.env}_human_readable.log",
                                        level:     config.human_log.human_readable_level,
                                        formatter: HumanLogFormatter.new)


    # Also log to JSON
    rawformatter      = SemanticLogger::Formatters::Raw.new
    safejsonformatter = proc do |log, logger|
      msg = rawformatter.(log, logger)
      begin
        JSON.generate(msg)
      rescue
        msg.force_encoding(::Encoding::UTF_8).to_json
      end
    end
    config.semantic_logger.add_appender(file_name: "log/#{Rails.env}.json",
                                        formatter: safejsonformatter)


    config.colorize_logging                   = true
    config.semantic_logger.backtrace_level    = :info
    config.rails_semantic_logger.quiet_assets = true
    config.rails_semantic_logger.ap_options   = { multiline: true }


    # Quiet some things down
    # A filter is either a regular expression matching what messages to include, or is
    # a Proc (Block of code) that returns true to allow the message to be logged, or false
    # indicating the message should not be logged.

    not_notifications_number = ->(log) {!/notifications_number/.match?(log.message.to_s)}
    not_render_msgs          = ->(log) {!/Render/.match?(log.message.to_s)}
    not_cancan               = ->(log) {!/CANCAN/.match?(log.message.to_s)}
    not_rack_started         = ->(log) {!/Started/.match?(log.message.to_s)}
    not_looking_for_partial  = ->(log) {!/Looking for/.match?(log.message.to_s)}

    not_sql_log         = ->(log) {log.payload.nil? or !(log.payload.has_key?(:sql))}
    not_sql_transaction = ->(log) {puts "Checking transaction"; log.payload.nil? || !(/transaction/.match? log.payload[:sql])}


    not_solr_queries      = ->(log) {!/Solr query/.match?(log.message)}
    not_solr_times        = ->(log) {!/Solr fetch/.match?(log.message)}
    not_solr_params       = ->(log) {!/Solr parameters/.match?(log.message.to_s)}
    not_solr_dumb_warning = ->(log) {!/without passing an explicit value for ':rows'/.match?(log.message.to_s)}

    # Ugh. Exists only for side-effect on log message. Can't do it in the logger
    # because I don't have access to this stuff. Need to stick it all in
    # Rails config, I guess.
    shorten_solr_queries = ->(log) do

    end


    def add_filters(klass, *filters)
      filters.each do |f|
        f0                  = klass.logger.filter
        klass.logger.filter = if f0.nil?
                                f
                              else
                                ->(log) {f0.(log) && f.(log)}
                              end
      end

      klass
    end

    # add_filters(Blacklight::CatalogController, not_looking_for_partial) unless config.human_log.looking_for_partial

    add_filters(ActiveRecord::Base, not_sql_log) unless config.human_log.log_sql
    add_filters(ActiveRecord::Base, not_sql_transaction) unless config.human_log.log_sql_transactions
    add_filters(ActionView::Base, not_render_msgs) unless config.human_log.log_render_msgs

    add_filters(Rails, not_cancan) unless config.human_log.log_cancan
    add_filters(Rails, not_solr_params) unless config.human_log.log_solr_params
    add_filters(Rails, not_solr_queries) unless config.human_log.log_solr_queries
    add_filters(Rails, not_solr_times) unless config.human_log.log_solr_times
    add_filters(Rails, not_solr_dumb_warning) unless config.human_log.log_solr_get_without_rows

    add_filters(Rails::Rack::Logger, not_rack_started) unless config.human_log.log_rack_started


  end

end





