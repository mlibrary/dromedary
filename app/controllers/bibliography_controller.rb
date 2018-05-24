class BibliographyController < ApplicationController

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

    config.default_solr_params = {
      rows: 20
    }

    config.document_solr_path = 'bibdoc'

    # Options for items to show per page, each number in the array represent another option to choose from.
    config.per_page = [20, 100]

    # What's the title field for each search result entry?
    config.index.title_field = 'title'

    config.index.display_type_field = "type"

    config.add_search_field("bib_keyword", label: "Everything") do |field|
      field.qt                    = "/bibsearch"
      # field.solr_local_parameters = {
      #   qf: '$headword_and_forms_qf',
      #   pf: '$headword_and_forms_pf',
      # }
    end
  end

end
