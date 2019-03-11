require_relative '../presenters/quotes/index_presenter'

class QuotesController < ApplicationController

  include Blacklight::Catalog


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
    # config.show.document_actions.delete(:email)
    # config.show.document_actions.delete(:sms)

    # Options for items to show per page, each number in the array represent another option to choose from.

    config.per_page            = [100, 500]
    config.default_solr_params = {
        rows: 100
    }

    # ############################################# #
    #             SEARCHES                          #
    # ############################################# #



    config.add_search_field("quote_everything", label: "Quotation including citation") do |field|
      field.qt                    = "/quotesearch"
      field.solr_local_parameters = {
          qf: '$quote_everything_qf',
          pf: '$quote_everything_pf',
      }
    end

    config.add_search_field("quote_quote", label: "Quotation text only") do |field|
      field.qt                    = "/quotesearch"
      field.solr_local_parameters = {
          qf: '$quote_quote_qf',
          pf: '$quote_quote_pf',
      }
    end


    # ############################################# #
    #             SORTING                           #
    # ############################################# #

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    #
    config.add_sort_field 'score desc', label: 'Relevance'
    config.add_sort_field 'quote_date_sort asc, author_sort asc', label: 'Date (oldest first)'
    config.add_sort_field 'quote_date_sort desc, author_sort asc', label: 'Date (newest first)'
    config.add_sort_field 'author_sort asc, title_sort asc', label: 'Author'


    # ############################################# #
    #             Views and Presenters              #
    # ############################################# #
    #
    config.index.document_presenter_class = Dromedary::Quotes::IndexPresenter

    def show404(*args)
      render "application/404", layout: 'static', status: 404, locals: {args: args, id: params['id']}
    end

  end
end
