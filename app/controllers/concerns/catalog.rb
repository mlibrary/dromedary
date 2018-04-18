#require 'fishrappr/search_state'

module Dromedary::Catalog
  extend ActiveSupport::Concern

  include Blacklight::Base

  # get search results from the solr index
  def index
    @current_action = 'dictionary'
  end

  def search
    @current_action = 'dictionary'
  end

  def bib
    @current_action = 'bibliography'
  end

  def home
    @current_action = 'home'
    render :layout => 'home'
  end


end
