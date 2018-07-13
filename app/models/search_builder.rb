# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior

  self.default_processor_chain += [:escape_intersticial_parens, :default_to_everything_search]


  # q"=>"{!qf=$quote_everything_qf pf=$quote_everything_pf}right",
  #
  # We'll say that no matter what is in 'q', we'll escape parens
  # for anything that's not in braces
  #
  # This might be a problem with the advanced search...

  EscapeWorthy = /([-\p{Alpha}])\((\p{Alpha}{1,3})\)/


  def escape_intersticial_parens(solr_params)
    current_q = solr_params['q']
    if current_q
      new_q            = current_q.gsub EscapeWorthy, '\1\\\\(\2\\\\)'
      solr_params['q'] = new_q
      solr_params['debug'] = 'true'
    end
  end

  def default_to_everything_search(solr_params)
    q = solr_params['q']
    if q.nil? or q == "" or q =~ /}\Z/
      solr_params['q'] = '*'
      blacklight_params['q'] = '*'
    end
  end

  ##
  # @example Adding a new step to the processor chain
  #   self.default_processor_chain += [:add_custom_data_to_query]
  #
  #   def add_custom_data_to_query(solr_parameters)
  #     solr_parameters[:custom] = blacklight_params[:user_value]
  #   end
end

