# frozen_string_literal: true
#
require_relative "concerns/catalog"

class CatalogController < ApplicationController

  #include Blacklight::

  include Blacklight::Catalog
  include Dromedary::Catalog

  # Force the


  configure_blacklight do |config|
    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response


    #----------------------------------------------------------
    #   Dromedary-only stuff
    #----------------------------------------------------------
    # config.add_nav_action(:search, partial: 'shared/nav/search')
    config.add_nav_action(:about, partial: 'shared/nav/about')
    config.add_nav_action(:help, partial: 'shared/nav/help')
    config.add_nav_action(:contact, partial: 'shared/nav/contact')

    config.navbar.partials.delete(:search_history)

    # Show page tools items
    #add_show_tools_partial(:print)
    config.show.document_actions.delete(:email)
    config.show.document_actions.delete(:sms)
    ##--------------------------------------------------------
    # Talking to solr
    ##--------------------------------------------------------
    #
    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      rows: 20
    }

    # The "normal" search path as defined as a requestHandler in solrconfig.xml
    # Often this is 'select'; the Blacklight default is 'search'.
    # See <requestHandler name="/search".../> in the solrconfig.xml
    # config.solr_path = 'search'

    # The "document" search handler, for getting a single document
    # See <requestHandler name="/document".../> in the solrconfig.xml

    config.document_solr_path = 'document'

    ##--------------------------------------------------------
    # Sorting and pagination in the Blacklight UI
    ##--------------------------------------------------------

    # Options for items to show per page, each number in the array represent another option to choose from.
    config.per_page = [20, 100]

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc', label: 'Relevance'
    config.add_sort_field 'sequence asc', label: 'Alphabetical'

    ##--------------------------------------------------------
    # The search results (index) page
    ##--------------------------------------------------------

    ## Default parameters to send on single-document requests to Solr.
    # These settings are the Blackligt defaults (see SearchHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.

    # What class should we use to render this?
    blacklight_config.index.document_presenter_class = Dromedary::IndexPresenter

    # What's the title field for each search result entry?
    config.index.title_field = 'official_headword'

    # How should we choose how to display this item? (maybe not used if
    # you only have one type of record)
    config.index.display_type_field = "type"

    # Add fields to the display
    # config.add_index_field 'orths', label: "Other forms"


    # solr field configuration for document/show views
    #config.show.title_field = 'title_display'
    #config.show.display_type_field = 'format'
    #config.show.thumbnail_field = 'thumbnail_path_ss'
    #
    # config.show.main_headword = 'main_headword'
    # config.show.headwords     = 'headwords'
    # config.show.definitions   = 'definitions'
    # config.show.pos           = 'pos'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically across a large set of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation (note: It is case sensitive when searching values)

    config.add_facet_field 'pos', label: 'Part of Speech', collapse: false
    config.add_facet_field 'discipline_usage', label: "Professional Usage", collapse: false
    config.add_facet_field 'etyma_language', label: "Source Language", collapse: false

    #     config.add_facet_field 'subject_topic_facet', label: 'Topic', limit: 20, index_range: 'A'..'Z'
    #     config.add_facet_field 'example_pivot_field', label: 'Pivot Field', :pivot => ['format', 'language_facet']

    # config.add_facet_field 'example_query_facet_field', label: 'Publish Date', :query => {
    #   :years_5  => {label: 'within 5 Years', fq: "pub_date:[#{Time.zone.now.year - 5 } TO *]"},
    #   :years_10 => {label: 'within 10 Years', fq: "pub_date:[#{Time.zone.now.year - 10 } TO *]"},
    #   :years_25 => {label: 'within 25 Years', fq: "pub_date:[#{Time.zone.now.year - 25 } TO *]"}
    # }


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!


    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'headword', label: 'Headwords'
    config.add_show_field 'pos_abbrev', label: 'Part of Speech'
    config.add_show_field 'discipline_usage', label: 'Professional Usage'
    config.add_show_field 'etyma_language', label: 'Source Language'
    config.add_show_field 'definition_text', label: 'Definition Text'
    config.add_show_field 'quote_text', label: 'Quotation Text'
    config.add_show_field 'quote_cd', label: 'Quotation CD'
    config.add_show_field 'quote_md', label: 'Quotation MD'
    config.add_show_field 'quote_rid', label: 'Quotation RID'
    config.add_show_field 'quote_title', label: 'Quotation Title'
    config.add_show_field 'headerword_exactish', label: 'Headword Exactish'
    config.add_show_field 'headword_only_suggestions', label: 'Headword Only Suggestions'
    config.add_show_field 'official_headword', label: 'Official Headword'
    config.add_show_field 'official_headword_exactish', label: 'Official Headword Exactish'
    config.add_show_field 'orth', label: 'Orth'
    config.add_show_field 'id', label: 'ID'
    config.add_show_field 'sequence', label: 'Sequence'
    config.add_show_field 'title', label: 'Title'
    config.add_show_field 'word_suggestion', label: 'Word Suggestion'
    config.add_show_field 'oed_norm', label: 'OED Norm'
    config.add_show_field 'keyword', label: 'Keyword'
    config.add_show_field 'json', label: 'JSON'
    config.add_show_field 'xml', label: 'XML'


    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a diffelrent one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.


    # config.add_search_field 'Keywords', label: 'Everything'

    config.add_search_field("hnf", label: "Headwords and Forms") do |field|
      field.qt                    = "/search"
      field.solr_parameters       = {:fq => 'type:entry'}
      field.solr_local_parameters = {
        qf: '$headword_and_forms_qf',
        pf: '$headword_and_forms_pf',
      }
    end

    # Just the headwords
    config.add_search_field("h", label: "Headwords only") do |field|
      field.qt                    = '/search'
      field.solr_parameters       = {:fq => 'type:entry'}
      field.solr_local_parameters = {
        qf: '$headword_only_qf',
        pf: '$headword_only_pf',
      }
    end

    # Anywhere
    config.add_search_field("anywhere", label: "Anywhere") do |field|
      field.qt                    = '/search'
      field.solr_parameters       = {:fq => 'type:entry'}
      field.solr_local_parameters = {
        qf: '$everything_qf',
        pf: '$everything_pf',
      }
    end

    # OED Modern English equivalent(ish)
    config.add_search_field("oed", label: "Modern English") do |field|
      field.qt                    = '/search'
      field.solr_parameters       = {:fq => 'type:entry'}
      field.solr_local_parameters = {
        qf: 'oed_norm',
        pf: 'oed_norm',
      }
    end

    # Etymology (why???)
    config.add_search_field('etyma', label: "Etymology") do |field|
      field.qt                    = '/search'
      field.solr_parameters       = {:fq => 'type:entry'}
      field.solr_local_parameters = {
        qf: "etyma_text",
        pf: "etyma_text",
      }
    end

    # Notes and definition (all the modern english, basically)
    config.add_search_field('notes_and_def', label: "Definition and Notes") do |field|
      field.qt                    = '/search'
      field.solr_parameters       = {:fq => 'type:entry'}
      field.solr_local_parameters = {
        qf: "definition_text^50 notes",
        pf: "definition_text^50 notes",
      }
    end

    # Citation search
    config.add_search_field("citation", label: "Citations") do |field|
      field.qt                    = '/search'
      field.solr_parameters       = {:fq => 'type:entry'}
      field.solr_local_parameters = {
        qf: '$citation_qf',
        pf: '$citation_pf'
      }
    end

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    # config.add_search_field('title') do |field|
    #   # solr_parameters hash are sent to Solr as ordinary url query params.
    #   field.solr_parameters = {:'spellcheck.dictionary' => 'title'}
    #
    #   # :solr_local_parameters will be sent using Solr LocalParams
    #   # syntax, as eg {! qf=$title_qf }. This is neccesary to use
    #   # Solr parameter de-referencing like $title_qf.
    #   # See: http://wiki.apache.org/solr/LocalParams
    #   field.solr_local_parameters = {
    #     qf: '$title_qf',
    #     pf: '$title_pf'
    #   }
    # end
    #
    # config.add_search_field('author') do |field|
    #   field.solr_parameters       = {:'spellcheck.dictionary' => 'author'}
    #   field.solr_local_parameters = {
    #     qf: '$author_qf',
    #     pf: '$author_pf'
    #   }
    # end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    # config.add_search_field('subject') do |field|
    #   field.solr_parameters       = {:'spellcheck.dictionary' => 'subject'}
    #   field.qt                    = 'search'
    #   field.solr_local_parameters = {
    #     qf: '$subject_qf',
    #     pf: '$subject_pf'
    #   }
    # end


    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 15

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path    = 'headword_and_forms_suggester'

    # Autocomplete setup.
    # The format is:
    #   search_name: {
    #     solr_endpoint: path_to_solr_handler,
    #     search_component_name: "mySuggester"
    #       }
    #
    # The "search_name" is the name given the search in the
    # `config.add_search_field(name, ...)` above.
    #
    config.autocomplete = {
      h:   {
        solr_endpoint:         "headword_only_suggester",
        search_component_name: "headword_only_suggester"
      },
      hnf: {
        solr_endpoint:         "headword_and_forms_suggester",
        search_component_name: "headword_and_forms_suggester"
      },
      oed: {
        solr_endpoint:         "oed_suggester",
        search_component_name: "oed_suggester"
      }
    }
  end
end
