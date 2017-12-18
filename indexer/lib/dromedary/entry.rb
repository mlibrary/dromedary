require 'nokogiri'
require 'yell'
require 'dromedary/entry/constants'
require 'dromedary/entry/form'
require 'dromedary/entry/sense'


module Dromedary

  def self.empty_array_on_error
    begin
      yield
    rescue => e
      $stderr.puts "Error: #{e.message}"
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

    def logger
      Dromedary::Entry::Constants::LOGGER
    end

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

      @etyma_xml = Dromedary.empty_array_on_error do
        doc.css('Dromedary ENTRYFREE ETYM').map(&:to_xml)
      end

      @etyma_languages = Dromedary.empty_array_on_error do
        doc.css('Dromedary ENTRYFREE ETYM LANG').map(&:text).map(&:strip)
      end

      @etyma = Dromedary.empty_array_on_error do
        doc.css('Dromedary ENTRYFREE ETYM HI').map(&:text).map(&:strip)
      end

      @senses = doc.xpath('/MED/ENTRYFREE/SENSE').map {|s| Sense.new(s)}
    rescue => err
      logger.warn "Problem with #{@filename}: #{err.message} #{err.backtrace}"
    end

    # @return [Array<String>] All the headwords from all the forms
    def headwords
      forms.flat_map(&:headwords)
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
      Dromedary::Entry::Constants::XSL.apply_to(Nokogiri::XML(@xml)).to_s
    end

    # Pretty-print the xml and return nil
    # @return [nil]
    def pp
      $stdout.puts pretty_xml
      nil
    end

    # @return [Array<String>] all the orths from all the forms
    def orths
      forms.flat_map(&:orths)
    end

    # @return [Array<String>] all the orth_alts from all the forms
    def orth_alts
      forms.flat_map(&:orth_alts)
    end


    # Create a hash that can be sent to solr
    def solr_doc
      doc = {}
      doc[:id] = id

      doc[:keywords] = Nokogiri::XML(xml).text # should probably just copyfield all the important stuff
      doc[:entry_xml] = xml

      doc[:main_headword] = headwords.first
      doc[:headwords] = headwords[1..-1] if headwords.size > 1
      doc[:pos] = forms.map(&:pos)
      doc[:definitions] = senses.map(&:def)
      doc[:quotes] = quotes.map(&:text)
      doc
    end


  end
end
