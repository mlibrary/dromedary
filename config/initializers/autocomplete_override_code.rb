# Blacklight autocomplete makes a bunch of assumptions about your
# autocomplete setup, not the least of which is that you're only
# going to have one autocomplete field.
#
# These module prepends do the least bit necessary to allow more
# flexible autocomplete.
#
# See the README.md for more about how to configure and make it work.


module Dromedary
  module Suggest
    module SearchOverride

      attr_reader :autocomplete_config
      # We need to hang onto the autocomplete_configuration
      def initialize(params, repository)
        autocomplete_config_name = params[:autocomplete_config]
        super
        if repository.blacklight_config.autocomplete
          @autocomplete_config = repository.blacklight_config.autocomplete[autocomplete_config_name]
        else
          @autocomplete_config = {
            solr_endpoint:         repository.blacklight_config.autocomplete_path,
            search_component_name: "mySuggester"
          }
        end

      end

      # suggestions will send along our configuration instead of just
      # the autocomplete_path
      def suggestions
        # If we haven't registered an autocomplete, just return the empty set
        return []  if @autocomplete_config.nil?
        Dromedary::Suggest::Response.new suggest_results, request_params, autocomplete_config
      end

      # Need to send along the configured path
      def suggest_handler_path
        @autocomplete_config['solr_endpoint']
      end

    end

    class Response
      attr_reader :response, :request_params, :suggest_path

      ##
      # Creates a suggest response
      # @param [RSolr::HashWithResponse] response
      # @param [Hash] request_params
      # @param [Hash] suggest_config
      def initialize(response, request_params, suggest_config)``
        @response       = response
        @request_params = request_params
        @suggest_path   = suggest_config[:solr_endpoint]
        @suggest_key    = suggest_config[:search_component_name]
      end

      ##
      # Trys the suggestor response to return suggestions if they are
      # present
      # @return [Array]
      def suggestions
        response.try(:[], "suggest").try(:[], @suggest_key).try(:[], request_params[:q]).try(:[], 'suggestions') || []
      end
    end

  end
end

# And do the prepend
Blacklight::SuggestSearch.prepend(Dromedary::Suggest::SearchOverride)
