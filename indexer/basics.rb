require 'nokogiri'


module MED

  def self.default_to_array
    begin
      yield
    rescue
      []
    end
  end


  # A single entry (xml file)
  # Exposes xml as e.xml or x.pretty_xml
  #
  # A single entry has a bunch of methods and parts
  #
  # entry:
  #   - xml (as e.xml or e.pretty_xml)
  #   - filename (MEDXXXX-word-pos.xml)
  #   - id (MEDxxxx)
  #   - seq (for sorting)
  #   - forms: (orths don't reflect https://mlit.slack.com/archives/C83KQTUGK/p1513099207000373)
  #     - pos (part of speech)
  #     - headwords (before the pos)
  #     - orhts (all orths as text)
  #     - orths_alt (all N1, N2, etc. attributes on the orths)
  #   - senses:
  #     - xml
  #     - usages (all; not differentiated by subdef)
  #     - subdefs (hash with keys :initial, 'a', 'b', etc.)
  #     - egs:
  #       - citations:
  #         - md (manuscript data, an integer)
  #         - cd (creation date, an integer)
  #         - quote:
  #           - xml
  #           - titles (from <TITLE> tags)
  #           - added  (from <ADDED> tags)
  #           - ovars  (from <OVAR> tags)
  #           - his (text within '<HI>' tags
  #         - bib:
  #           - xml
  #           - stencils:
  #             - rid (hyperbib id)
  #             - date (actual text)
  #             - his (text within <HI> tags)
  #             - title (text within <TITLE> tags)
  #
  class Entry

    # @return [String] the raw XML from the file
    attr_reader :xml

    # @return [String, nil] The filename passed, if there was one
    attr_reader :filename

    # @return [String] the MEDXXXX id
    attr_reader :id

    # @return [String] The sequence
    attr_reader :seq
    attr_reader :forms
    attr_reader :etyma
    attr_reader :etyma_languages
    attr_reader :etyma_xml
    attr_reader :senses

    # @param filename_or_handle [String, #read] A filename (path) or a readable IO object
    # @return [Entry] the filled-in entry, with all its subparts
    def initialize(filename_or_handle)
      return if filename_or_handle == :empty
      f = if filename_or_handle.respond_to? :read
            @filename = :stream
            filename_or_handle
          else
            @filename = filename_or_handle
            File.open(filename_or_handle)
          end

      @xml = f.read
      f.close
      # Lowercase all the tags
      doc = Nokogiri::XML(@xml) do |config|
        config.nononet.nonoent.nonoerror.dtdload
      end

      @xml = doc.to_xml

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
    rescue => err
      require 'pry'; binding.pry
    end

    def set_sense_defset
      senses.each {|s| s.defset = s.split_defs(s.defs.first)}
    rescue => err
      require 'pry'; binding.pry
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

    def pretty_xml
      XSL.apply_to(Nokogiri::XML(@xml)).to_s
    end

    XSLSS = <<-EOXSL
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" encoding="UTF-8"/>
  <xsl:param name="indent-increment" select="'   '"/>
  <xsl:template name="newline">
    <xsl:text disable-output-escaping="yes">
</xsl:text>
  </xsl:template>
  <xsl:template match="comment() | processing-instruction()">
    <xsl:param name="indent" select="''"/>
    <xsl:call-template name="newline"/>
    <xsl:value-of select="$indent"/>
    <xsl:copy />
  </xsl:template>
  <xsl:template match="text()">
    <xsl:param name="indent" select="''"/>
    <xsl:call-template name="newline"/>
    <xsl:value-of select="$indent"/>
    <xsl:value-of select="normalize-space(.)"/>
  </xsl:template>
  <xsl:template match="text()[normalize-space(.)='']"/>
  <xsl:template match="*">
    <xsl:param name="indent" select="''"/>
    <xsl:call-template name="newline"/>
    <xsl:value-of select="$indent"/>
      <xsl:choose>
       <xsl:when test="count(child::*) > 0">
        <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates select="*|text()">
           <xsl:with-param name="indent" select="concat ($indent, $indent-increment)"/>
         </xsl:apply-templates>
         <xsl:call-template name="newline"/>
         <xsl:value-of select="$indent"/>
        </xsl:copy>
       </xsl:when>
       <xsl:otherwise>
        <xsl:copy-of select="."/>
       </xsl:otherwise>
     </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
    EOXSL

    XSL = Nokogiri::XSLT(XSLSS)

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

    attr_reader :def, :usages, :egs
    attr_accessor :subdefs, :xml

    def initialize(nokonode)
      return if nokonode == :empty
      @xml = nokonode.to_xml
      @def = nokonode.at('DEF').map(&:text)
    end

    raise "Sense has #{@defs.size} defs: #{nokonode}" unless @defs.size == 1

    @subdefs = split_defs(@defs[0])

    @usages = MED.default_to_array do
      nokonode.css('USG').map(&:text).uniq
    end

    @egs = nokonode.css('EG').map {|x| EG.new(x)}
  end

  # We want to split on an '(a)' or the like
  # when preceded by
  #   * the beginning of the string
  #   * a semi-colon or colon followed by whitespace
  DEF_SPLITTER = /(?:\A|(?:[;:]\s+))(\([a-z]\))/
  DEF_LETTER   = /\(([a-z])\)/

  def split_defs(def_text)
    components  = def_text.chomp('.').split(DEF_SPLITTER)
    initial     = components.shift
    h           = {}
    h[:initial] = initial
    until components.empty?
      m = DEF_LETTER.match components.shift
      raise "Wackiness with definition: #{def_text}" unless m
      letter = m[1]
      subdef = components.shift
      raise "No def after letter" unless subdef
      h[letter] = subdef
    end
    h
  rescue => err
    $stderr.puts "Problem with #{defs}"
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

  attr_reader :quote, :cd, :md, :quote, :bib

  def initialize(nokonode)
    @md    = nokonode.attr('MD') && nokonode.attr('MD').to_i
    @cd    = nokonode.attr('CD') && nokonode.attr('CD').to_i
    @quote = Quote.new(nokonode.at('Q'))
    @bib   = Bib.new(nokonode.at('BIBL'))

  end

end

class Quote
  attr_reader :titles, :added, :ovars, :his, :text, :xml

  def initialize(nokonode)
    @titles = MED.default_to_array {nokonode.css("TITLE").map(&:text)}.uniq
    @added  = MED.default_to_array {nokonode.css("ADDED").map(&:text)}.uniq
    @ovars  = MED.default_to_array {nokonode.css("OVARS").map(&:text)}.uniq
    @his    = MED.default_to_array {nokonode.css("HI").map(&:text)}.uniq
    @text   = nokonode.text
    @xml    = nokonode.to_xml
  end

end

class Bib

  attr_reader :stencils, :xml

  def initialize(nokonode)
    @stencils = nokonode.css('STNCL').map {|x| Stencil.new(x)}
    @xml      = nokonode.to_xml
  end


end

class Stencil

  attr_reader :rid, :date, :his, :title

  def initialize(nokonode)
    @rid = nokonode.attr('RID')
    (@date = nokonode.at('DATE')) and (@date = @date.text)
    @his = nokonode.css('HI').map(&:text).uniq
    (@title = nokonode.at('TITLE')) and (@title = @title.text)
  end
end


end


