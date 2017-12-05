require 'nokogiri'


module MED

  def self.default_to_array
    begin
      yield
    rescue
      []
    end
  end

  class Entry

    attr_reader :xml,
                :id, :seq,
                :forms,
                :etyma, :etyma_languages, :etyma_xml,
                :senses

    def initialize(filename_or_handle)
      return if filename_or_handle == :empty
      f = if filename_or_handle.respond_to? :read
            filename_or_handle
          else
            File.open(filename_or_handle)
          end

      @xml = f.read
      f.close
      # Lowercase all the tags
      doc = Nokogiri::XML(@xml) do |config|
        config.nononet.nonoent.nonoerror.dtdload
      end

      # Lowercase the node names
      doc.traverse {|node| node.name = node.name.upcase if node.class == Nokogiri::XML::Element}


      @id  = doc.css('ENTRYFREE').first.attr('ID')
      @seq = doc.css('ENTRYFREE').first.attr('SEQ')

      @forms = doc.xpath('MED/ENTRYFREE/FORM').map {|f| Form.new(f)}

      @etyma_xml = MED.default_to_array do
        doc.css('MED ENTRYFREE ETYM').map(&:to_xml)
      end

      @etyma_languages = MED.default_to_array do
        doc.css('MED ENTRYFREE ETYM LANG').map(&:text).map(&:strip)
      end

      @etyma = MED.default_to_array do
        doc.css('MED ENTRYFREE ETYM HI').map(&:text).map(&:strip)
      end

     @senses = doc.xpath('/MED/ENTRYFREE/SENSE').map {|s| Sense.new(s)}
    end
    
    def headwords
      forms.flat_map(&:headwords)
    end

    def egs
      senses.flat_map(&:egs)
    end

    def citations
      egs.flat_map(&:citations)
    end

    def quotes
      citations.flat_map(&:quote)
    end

    def bibs
      citations.map(&:bib)
    end

    def stencils
      bibs.flat_map(&:stencils)
    end

    def rids
      stencils.map(&:rid)
    end
  end


  class Form
    attr_reader :pos,
                :orths, :orth_alts, :headwords

    def initialize(nokonode)
      return if nokonode == :empty
      @pos       = (nokonode.at('POS') and nokonode.at('POS').text.strip) # need to translate?
      @headwords = self.find_headwords(nokonode)
      @orths     = nokonode.xpath('ORTH').map(&:text)
      @orth_alts = nokonode.xpath('ORTH').flat_map do |o|
        o.attributes.select {|k, v| k =~ /\AN\d+/}.values.map(&:value)
      end
    end

    def find_headwords(node)
      headwords = []
      node.xpath('(POS|ORTH)').each do |n|
        break if n.name == 'POS'
        headwords << n.text
      end
      headwords
    end


  end

  class Sense

    attr_reader :defs, :usages, :egs

    def initialize(nokonode)
      return if nokonode == :empty
      @defs = MED.default_to_array do
        nokonode.css('DEF').map(&:text)
      end

      @usages = MED.default_to_array do
        nokonode.css('USG').map(&:text).uniq
      end

      @egs = nokonode.css('EG').map {|x| EG.new(x)}

    end

  end

  class EG

    attr_reader :citations

    def initialize(nokonode)
      return if nokonode == :empty
      @citations = nokonode.xpath('CIT').map {|x| CIT.new(x)}
    end

  end

  class CIT

    attr_reader :node, :quote, :cd, :md, :quote, :bib

    def initialize(nokonode)
      @md    = nokonode.attr('MD') && nokonode.attr('MD').to_i
      @cd    = nokonode.attr('CD') && nokonode.attr('CD').to_i
      @quote = Quote.new(nokonode.at('Q'))
      @bib   = Bib.new(nokonode.at('BIBL'))

    end

  end

  class Quote
    attr_reader :node, :titles, :added, :ovars, :his, :text, :xml

    def initialize(nokonode)
      @titles = MED.default_to_array {nokonode.css("TITLE").map(&:text)}.uniq
      @added  = MED.default_to_array {nokonode.css("ADDED").map(&:text)}.uniq
      @ovars  = MED.default_to_array {nokonode.css("OVARS").map(&:text)}.uniq
      @his    = MED.default_to_array {nokonode.css("HI").map(&:text)}.uniq
      @text   = nokonode.text
      @xml   = nokonode.to_xml
    end

  end

  class Bib

    attr_reader :node, :stencils, :xml

    def initialize(nokonode)
      @stencils = nokonode.css('STNCL').map {|x| Stencil.new(x)}
      @xml   = nokonode.to_xml
    end


  end

  class Stencil

    attr_reader :node, :rid, :date, :his, :title

    def initialize(nokonode)
      @rid = nokonode.attr('RID')
      (@date = nokonode.at('DATE')) and (@date = @date.text)
      @his = nokonode.css('HI').map(&:text).uniq
      (@title = nokonode.at('TITLE')) and (@title = @title.text)
    end
  end


end


