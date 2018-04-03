module MedQuotesHelper

	  def med_quotes_help(sense)
      quotes = {}
      egs = sense.egs
      egs.each do |eg|
        subdef_index = eg.subdef_entry
        citations = eg.citations
        cite_count = 0
        if !citations.empty?
          subdef_arr = []
          citations.each do |cite|
            sten = cite.bib.stencil
            sten_date = get_quote_value(sten.date)
            sten_title = get_quote_value(sten.title)
            sten_title  = '<span class="cite_bib_stencil_title" style="font-style: italic;">' + sten_title  + '</span>'
            sten_ms = get_quote_value(sten.ms)
            sten_rid =  get_quote_value(sten.rid)
            cite_bib_scope = get_quote_value(cite.bib.scope)
            cite_quote_text =  get_quote_value(cite.quote.text)
            cite_link = "https://quod.lib.umich.edu/cgi/m/mec/hyp-idx?type=id&id=#{sten_rid}"

            puts "sten_date: " + sten_date
            puts "sten_title: " + sten_title
            puts "sten_ms: " + sten_ms
            puts "sten_rid: " + sten_rid
            puts "cite_bib_scope: " + cite_bib_scope
            puts "cite_quote_text: " + cite_quote_text
            puts "cite_link: " + cite_link

            quote_str = '<a href="' + cite_link + '" > ' + sten_date + ' ' + sten_title
            quote_str = quote_str + sten_ms + '</a> ' + cite_bib_scope + ' ' + cite_quote_text
            
            puts "quote_str: " + quote_str

            subdef_arr.push quote_str
          end # citations.each
          quotes[subdef_index] = subdef_arr
        end # !citations.empty?
      end # egs.each
      quotes
    end # def

    private

    def get_quote_value(attr)
      if attr.kind_of?(Array)
        return attr.empty? ? '' : attr.first
      end

      if attr.nil? || attr.empty?
        return ''
      else
        return attr
      end
    end

end
