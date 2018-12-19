# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior

  self.default_processor_chain += [:yogh_to_ezh,
                                   :escape_intersticial_parens,
                                   :escape_prefix_suffix_dash,
                                   :default_to_everything_search]


  # q"=>"{!qf=$quote_everything_qf pf=$quote_everything_pf}right",
  #
  # We'll say that no matter what is in 'q', we'll escape parens
  # for anything that's not in braces
  #
  # This might be a problem with the advanced search...

  Parens_EscapeWorthy = /([-\p{Alpha}])\((\p{Alpha}{1,3})\)/


  # TODO: Get these values from blacklight_config
  NULL_SEARCH_SORT = {
     'catalog' => 'sequence asc',
     'bibliography' => 'title_sort asc, author_sort asc',
     'quotes' => 'quote_date_sort asc, author_sort asc'
  }


  # These two characters are equivalent
  def yogh_to_ezh(solr_params)
    solr_params['q'] = solr_params['q'].gsub(/[Ȝȝ]/, 'ʒ')
  end

  # Sometimes, you gotta escape the parens so things parse right
  def escape_intersticial_parens(solr_params)
    current_q = solr_params['q']
    if current_q
      new_q            = current_q.gsub Parens_EscapeWorthy, '\1\\\\(\2\\\\)'
      solr_params['q'] = new_q
      solr_params['debug'] = 'true'
    end
  end

  # There are prefixes and suffixes in the dictionary -- we want to
  # escape the leading- or trailing- dashes
  #
  # This will also have the effect of making '-' no longer work
  # as a unary NOT operator.
  #
  # Note that the solr query is generated as something like
  # {!qf=$headword_and_forms_qf pf=$headword_and_forms_pf}-ward
  # ...so the beginning of the prefix actually follows a '}'

  def escape_prefix_suffix_dash(solr_params)
    q = solr_params['q']
    oq = q
    q = q.gsub(/\}\-/, '}\\\\-')
    q = q.gsub(/\s+-/, ' \\\\-')
    q = q.gsub(/\-\s+/, '\\\\- ')
    q = q.gsub(/\-\Z/, '\\\\-')
    solr_params['q'] = q
    File.open('dash.txt', 'w:utf-8') {|f| f.puts "#{oq}\n#{q}"}
  end

  def default_to_everything_search(solr_params)
    q = solr_params['q']
    if q.nil? or q == "" or q =~ /}\Z/
      solr_params['q'] = String(q) + '*'
      blacklight_params['q'] = '*'

      solr_params['sort'] = NULL_SEARCH_SORT[blacklight_params['controller']]

      blacklight_params['sort'] = NULL_SEARCH_SORT[blacklight_params['controller']]
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

