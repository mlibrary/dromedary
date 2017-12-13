require 'nokogiri'
require 'yell'


module MED

  def self.default_to_array
    begin
      yield
    rescue
      []
    end
  end

  LOGGER = Yell.new(STDOUT)


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
  #           - highlighted_phrases (text within '<HI>' tags
  #         - bib:
  #           - xml
  #           - stencils:
  #             - rid (hyperbib id)
  #             - date (actual text)
  #             - highlighted_phrases (text within <HI> tags)
  #             - title (text within <TITLE> tags)
  #
  # In addition to the hierarchical structure, the Entry exposes
  # a bunch of convenience methods that dig into the substructures
  # (e.g., headwords, rids, etc.)
  class Entry

    # @return [String] the raw XML from the file, !!!with all tags uppercased!!!
    attr_reader :xml

    # @return [String, nil] The filename passed, if there was one
    attr_reader :filename

    # @return [String] the MEDXXXX id
    attr_reader :id

    # @return [String] The sequence
    attr_reader :seq

    # @return [Array<Form>] The forms
    attr_reader :forms

    # @return [Array<String>] The etyma "words" (everything in <HI> tags)
    attr_reader :etyma

    # @return [Array<String>] The unaltered language codes in the etyma
    attr_reader :etyma_languages

    # @return [String] the xml for this etyma
    attr_reader :etyma_xml

    # @return [Array<Sense>] The Sense objects for this entry
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

      # Load the doc. See Nokogiri docs for config explanation;
      # basically it says, "Yes, go get the DTD"
      doc = Nokogiri::XML(@xml) do |config|
        config.nononet.nonoent.nonoerror.dtdload
      end

      # Normalize the case of the node names
      doc.traverse {|node| node.name = node.name.upcase if node.class == Nokogiri::XML::Element}

      # ...and get the XML
      @xml = doc.to_xml


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
      LOGGER.warn "Problem with #{@filename}: #{err.message} #{err.backtrace}"
    end

    # @return [Array<String>] All the headwords from all the forms
    def headwords
      forms.flat_map(&:headwords)
    end

    def orths
      forms.flat_map(&:orths)
    end

    # @return [Array<EG>] All the EG objects from all the senses
    def egs
      senses.flat_map(&:egs)
    end

    # @return [Array<Citation>] All the Citation objects from all the egs
    def citations
      egs.flat_map(&:citations)
    end

    # @return [Array<Quote>] All the Quote objects from all the citations
    def quotes
      citations.flat_map(&:quote)
    end

    # @return [Array<String>] All the quotes as text
    def quote_texts
      citations.flat_map(&:quote).flat_map(&:text)
    end

    # @return [Array<Bib>] All the Bib objects from all the citations
    def bibs
      citations.map(&:bib)
    end

    # @return [Array<Stencil>] All the Stencil objects from all the bibs
    def stencils
      bibs.flat_map(&:stencils)
    end

    # @return [Array<String>] All the rids (hyperbib ids) from all the stencils
    def rids
      stencils.map(&:rid)
    end

    # @return [String] pretty-printable XML
    def pretty_xml
      XSL.apply_to(Nokogiri::XML(@xml)).to_s
    end

    # Pretty-print the xml and return nil
    # @return [nil]
    def pp
      puts pretty_xml
      nil
    end

    # Get all the orths from all the forms
    def orths
      forms.flat_map(&:orths)
    end

    # Get all the orth_alts from all the forms
    def orth_alts
      forms.flat_map(&:orth_alts)
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


  # The Form has a bunch of ways of representing the word. It has (probably)
  # several Orths; each of which is a "word". Some orths are "headwords", the
  # most important variants.
  #
  # Some Orths have alternate spellings; these are combined across orth
  # entries in #orth_alts, because I can't imagine why we'd use them
  # except for indexing.
  class Form

    # @return [String] the unaltered part of speech
    attr_reader :pos

    # @return [Array<String>] The words in all the ORTH tags, stripped to be text
    attr_reader :orths

    # @return [Array<String>] The words from the N1, N2, ... attributes in the ORTHs
    attr_reader :orth_alts

    # @return [Array<String>] The headwords
    attr_reader :headwords

    # @param [Nokogiri::XML::Element] nokonode The nokogiri node for this element
    def initialize(nokonode)
      return if nokonode == :empty
      @pos       = (nokonode.at('POS') and nokonode.at('POS').text.strip) # need to translate?
      @headwords = self.find_headwords(nokonode)
      @orths     = nokonode.xpath('ORTH').map(&:text).reject{|x| x.empty?}
      @orth_alts = nokonode.xpath('ORTH').flat_map do |o|
        o.attributes.select {|k, v| k =~ /\AN\d+/}.values.map(&:value)
      end
    end


    # Extract the headwords from the nokogiri node
    # @!visibility private
    def find_headwords(nokonode)
      headwords = []
      nokonode.xpath('(POS|ORTH)').each do |n|
        break if n.name == 'POS'
        headwords << n.text
      end
      headwords
    end


  end

  class Sense

    # @return [String] the definition, as an unadorned string
    attr_reader :def


    # The sub-definitions, returned as a hash of the form
    #  {
    #   :initial => Empty string, the whole (unsubbed) definition,
    #               or the 'initial' text before "(a)"
    #   'a' => subdef (a),
    #   'b' => subdef (b),
    #   etc.
    #  }
    # @return [Hash] the initial (or full) text of the definition and subdefs
    attr_reader :subdefs

    # @return [Array<String>] The text of the "usages" (indicating used in
    # the medical community or whatever -- the <USG> tags).
    attr_reader :usages

    # @return [Array<EG>] all the EG objects for this sense
    attr_reader :egs

    # @return [String] the raw XML snippet for this Sense
    attr_reader :xml

    # @param [Nokogiri::XML::Element] nokonode The nokogiri node for this element
    def initialize(nokonode)
      return if nokonode == :empty
      @xml     = nokonode.to_xml
      @def     = nokonode.at('DEF').text
      @subdefs = split_defs(@def)

      @usages = MED.default_to_array do
        nokonode.css('USG').map(&:text).uniq
      end

      @egs = nokonode.css('EG').map {|x| EG.new(x)}

    end

    # We want to split on an '(a)' or the like
    # when preceded by
    #   * the beginning of the string
    #   * a semi-colon or colon followed by whitespace
    DEF_SPLITTER = /(?:\A|(?:[;:]\s+))(\([a-z]\)\s*)/
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
    end
  end


  # EG == "Example Given" a set of related citations. Entries often
  # have more than one EG section, one for each sub-definition.
  class EG

    # @return [Array<Citation>] The citations for this set of examples
    attr_reader :citations

    # @return [String, nil] The sub-definition this set of citations refers to
    attr_reader :subdef_entry

    # @param [Nokogiri::XML::Element] nokonode The nokogiri node for this element
    def initialize(nokonode)
      return if nokonode == :empty
      @citations    = nokonode.xpath('CIT').map {|x| Citation.new(x)}
      @subdef_entry = nokonode.attribute('N') && nokonode.attribute('N').value.downcase
    end

  end


  # An individual citation always has a bib entry and a quote. It may
  # also have integer-ized guesses at the years the work was created
  # (cd) and the year this particular manuscript is from (md)
  class Citation

    # @return [Quote] The quotation object for this citataion
    attr_reader :quote

    # @return [Integer] the year the work was originally created (written)
    attr_reader :cd

    # @return [Integer] the year of this specific manuscript
    attr_reader :md

    # @return [Bib] The Bib object for this citation
    attr_reader :bib

    # @param [Nokogiri::XML::Element] nokonode The nokogiri node for this element
    def initialize(nokonode)
      @md    = nokonode.attr('MD') && nokonode.attr('MD').to_i
      @cd    = nokonode.attr('CD') && nokonode.attr('CD').to_i
      @quote = Quote.new(nokonode.at('Q'))
      @bib   = Bib.new(nokonode.at('BIBL'))

    end

  end

  # A Quote can have a bunch of parts, almost all of them optional. At its
  # core, though, it's just a string of text with some inline markup that
  # we may or may not want to worry about
  #
  # All the attributes are just (often empty) arrays of text strings marked
  # up with the given tag
  class Quote
    attr_reader :titles
    attr_reader :added
    attr_reader :ovars
    attr_reader :highlighted_phrases
    attr_reader :text
    attr_reader :xml

    def initialize(nokonode)
      @titles              = MED.default_to_array {nokonode.css("TITLE").map(&:text)}.uniq
      @added               = MED.default_to_array {nokonode.css("ADDED").map(&:text)}.uniq
      @ovars               = MED.default_to_array {nokonode.css("OVARS").map(&:text)}.uniq
      @highlighted_phrases = MED.default_to_array {nokonode.css("HI").map(&:text)}.uniq
      @text                = nokonode.text
      @xml                 = nokonode.to_xml
    end

  end

  # A Bib is just a stencil. Stored as a unit because we need to hang onto
  # the XML
  class Bib

    attr_reader :stencil, :xml

    def initialize(nokonode)
      stencil_node = nokonode.at('STNCL')
      @stencil = Stencil.new(stencil_node) if stencil_node
      @xml      = nokonode.to_xml
    end
  end

  # A Stencil is a a bibliographic reference. Here we pull
  # out, if there are any, highlighted phrases, the title, and the
  # non-parsed date.
  #
  # We also have the "rid", a unique identifier used to cross-reference
  # to the hyperbib
  class Stencil

    attr_reader :rid, :date, :highlighted_phrases, :title

    def initialize(nokonode)
      @rid = nokonode.attr('RID')
      (@date = nokonode.at('DATE')) and (@date = @date.text)
      @highlighted_phrases = nokonode.css('HI').map(&:text).uniq
      (@title = nokonode.at('TITLE')) and (@title = @title.text)
    end
  end


end


