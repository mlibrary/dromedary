require_relative '../presenters/bibliography/index_presenter'
class BibliographyController < ApplicationController

  include Blacklight::Catalog


  configure_blacklight do |config|
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'dismax'
    config.advanced_search[:form_solr_parameters] ||= {}

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

    config.per_page            = [100]
    config.default_solr_params = {
        rows: 100
    }

    # Solr path to the single-document handler
    config.document_solr_path = 'bibdoc'

    # What's the title field for each search result entry?
    config.index.title_field = 'title'

    # In theory, this would allow us to switch view templates based on the
    # value of the solr field listed.
    config.index.display_type_field = "type"

    # ############################################# #
    #             SEARCHES                          #
    # ############################################# #



    config.add_search_field("bib_keyword", label: "Everything") do |field|
      field.qt                    = "/bibsearch"
      field.solr_local_parameters = {
          qf: '$bib_everything_qf',
          pf: '$bib_everything_pf',
      }
    end


    config.add_search_field("bib_author_title", label: "Author/Title") do |field|
      field.qt                    = "/bibsearch"
      field.solr_local_parameters = {
          qf: '$bib_author_title_qf',
          pf: '$bib_author_title_pf',
      }
    end

    config.add_search_field("bib_external_references", label: "External References") do |field|
      field.qt                    = "/bibsearch"
      field.solr_local_parameters = {
          qf: '$bib_external_references_qf',
          pf: '$bib_external_references_pf',
      }
    end

    config.add_search_field("bib_lalme", label: "LALME/LAEME") do |field|
      field.qt                    = "/bibsearch"
      field.solr_local_parameters = {
          qf: '$bib_lalme_qf',
          pf: '$bib_lalme_pf',
      }
    end

    config.add_search_field("bib_manuscript", label: "Manuscripts") do |field|
      field.qt                    = "/bibsearch"
      field.solr_local_parameters = {
          qf: '$bib_manuscript_qf',
          pf: '$bib_manuscript_pf',
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
    config.add_sort_field 'title_sort asc, author_sort asc', label: 'Title'
    config.add_sort_field 'author_sort asc, title_sort asc', label: 'Author'



    # ############################################# #
    #             FACETS                            #
    # ############################################# #

    config.add_facet_fields_to_solr_request!
    config.add_facet_field 'lalme_expansion', label: 'LALME Region', collapse: false

  end


  # ############################################# #
  #             Views and Presenters              #
  # ############################################# #
  #
  blacklight_config.index.document_presenter_class = Dromedary::Bib::IndexPresenter



  # ############################################# #
  #            Allow HYP...IDs to redirect
  #        and force uppercase IDs                #
  # ############################################# #
  #

  def show
    id = params[:id]
    new_id = id.upcase
    if id =~ /HYP/
      new_id = Dromedary.hyp_to_bibid[id]
    end
    if id != new_id
      redirect_to "/bibliography/#{new_id}", status: :moved_permanently
    else
      super
    end
  end

end
