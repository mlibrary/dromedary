# require 'fishrappr/search_state'

module Dromedary::Catalog
  extend ActiveSupport::Concern

  include Blacklight::Controller

  # get search results from the solr index
  def index
    (@response, deprecated_document_list) = search_service.search_results
    @document_list = deprecated_document_list
    respond_to do |format|
      format.html {} # no longer store_preferred_view
      format.rss { render layout: false }
      format.atom { render layout: false }
      format.json do
        @presenter = Blacklight::JsonPresenter.new(@response,
          @document_list,
          facets_from_request,
          blacklight_config)
      end

      # additional_response_formats(format)
      # document_export_formats(format)
    end
  end

  def search
  end

  def bib
  end

  def home
    render layout: "home"
  end
end
