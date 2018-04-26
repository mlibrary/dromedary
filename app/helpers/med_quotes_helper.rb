module MedQuotesHelper

	  def med_quotes_help(sense, doc_presenter)
      quotes = {}
      quote_count = 0
      egs = sense.egs
      egs.each do |eg|
        subdef_index = eg.subdef_entry
        citations = eg.citations
        if !citations.empty?
          subdef_arr = []
          citations.each do |cite|
            sten = cite.bib.stencil
            # sten_date = get_quote_value(sten.date)
            # sten_title = get_quote_value(sten.title)
            # sten_title  = '<span class="cite_bib_stencil_title">' + sten_title  + '</span>'
            # sten_ms = get_quote_value(sten.ms)
            sten_rid =  get_quote_value(sten.rid)
            # cite_bib_scope = get_quote_value(cite.bib.scope)
            # cite_quote_text =  get_quote_value(cite.quote.text)
            cite_link = "https://quod.lib.umich.edu/cgi/m/mec/hyp-idx?type=id&id=#{sten_rid}"

            # Rails.logger.debug "sten_date: " + sten_date
            # Rails.logger.debug "sten_title: " + sten_title
            # Rails.logger.debug "sten_ms: " + sten_ms
            # Rails.logger.debug "sten_rid: " + sten_rid
            # Rails.logger.debug "cite_bib_scope: " + cite_bib_scope
            # Rails.logger.debug "cite_quote_text: " + cite_quote_text
            # Rails.logger.debug "cite_link: " + cite_link

            # quote_str = '<a href="' + cite_link + '" > ' + sten_date + ' ' + sten_title
            # quote_str = quote_str + sten_ms + '</a> ' + cite_bib_scope + ' ' + cite_quote_text

            # binding.pry

            

            puts "IN med_quotes_help doc_presenter IS: #{doc_presenter}"

            puts "IN med_quotes_help CITE IS: #{cite}"
            cite_html = doc_presenter.cit_html(cite)
            puts "IN med_quotes_help AFTER doc_presenter.cit_html(cite) cite_html IS: #{cite_html}"

            quote_str = '<a href="' + cite_link + '" > ' + cite_html + '</a> '

            # Rails.logger.debug "quote_str: " + quote_str
            quote_count += 1
            subdef_arr.push quote_str
          end # citations.each
          quotes[subdef_index] = subdef_arr
        end # !citations.empty?
      end # egs.each
      return quotes, quote_count
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
