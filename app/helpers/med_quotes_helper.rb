module MedQuotesHelper

	  def med_quotes_help(sense)
    puts "IN med_quotes_help ============================"
    quotes = Hash.new # create empty hash
    egs = sense.egs
    if  !egs.nil? && egs.count > 0
      egs.each do |eg|
        subdef_index = eg.subdef_entry
        return if subdef_index.empty?
        citations = eg.citations
        cite_count = 0
        if !citations.nil? && citations.count > 0
          subdef_arr = []
          citations.each do |cite|
            subdef_arr.push cite.quote.text
          end # citations.each
          quotes[subdef_index] = subdef_arr
        end # if !citations.nil?
      end #egs.each
    end # if !egs.nil?
    quotes
  end # def

end
