#require 'fishrappr/search_state'

module Dromedary::Catalog
  extend ActiveSupport::Concern

  include Blacklight::Base

  # get search results from the solr index
  def index

    (@response, @document_list) = search_results(params)
    respond_to do |format|
      format.html { } # no longer store_preferred_view
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
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

  def home
    render :layout => 'home'
  end

end