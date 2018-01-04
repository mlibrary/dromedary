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

    # @return [Form] The form
    attr_reader :form

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


      entry = doc.at('ENTRYFREE')
      @id  = entry.attr('ID')
      @seq = entry.attr('SEQ')

      @form = Form.new(entry.at('FORM'))

      @etyma_xml = Dromedary.empty_array_on_error do
        entry.xpath('ETYM').map(&:to_xml)
      end

      @etyma_languages = Dromedary.empty_array_on_error do
        entry.xpath("ETYM/LANG").map(&:text).map(&:strip)
      end

      @etyma = Dromedary.empty_array_on_error do
        entry.xpath("ETYM/HI").map(&:text).map(&:strip)
      end

      @senses = entry.xpath('SENSE').map {|s| Sense.new(s)}
    rescue => err
      logger.warn "Problem with #{@filename}: #{err.message} #{err.backtrace}"
    end

    # @return [Orth] the headword (as an Orth object)
    def headword
      form.headword
    end

    # @return [String] The display word as determined by the Form
    def display_word
      form.display_word
    end

    # @return [Array<Orth>] all the non-headword orths
    def orths
      form.orths
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



    # Create a hash that can be sent to solr
    def solr_doc
      doc = {}
      doc[:id] = id
      doc[:type] = 'entry'

      doc[:keywords] = Nokogiri::XML(xml).text # should probably just copyfield all the important stuff
      doc[:xml] = xml

      if form and form.pos
        doc[:pos_abbrev] = form.pos.gsub(/\A([^.]+).*\Z/, "\\1").downcase
        doc[:pos] = form.pos
      end

      doc[:main_headword] = display_word
      doc[:headwords] = headword.regs.unshift(headword.orig) - [display_word]

      doc[:orths] = (form.orths.flat_map(&:orig) + form.orths.flat_map(&:regs)).flatten.uniq

      doc[:definitions] = senses.map(&:definition) if senses and senses.size > 0
      doc[:quotes] = quotes.map(&:text)
      doc
    end


    # Turn this into a hash that can be round-tripped to JSON
    # @return [Hash] a hash suitable for JSON round-tripping
    def to_h
      {
        xml: xml,
        id: id,
        filename: filename.to_s,
        seq: seq,
        form: form.to_h,
        etyma: etyma,
        etyma_languages: etyma_languages,
        etyma_xml: etyma_xml,
        senses: senses.map(&:to_h),
      }
    end

    def self.from_h(h)
      obj = allocate
      obj.fill_from_hash(h)
      obj
    end

    def fill_from_hash(h)
      @xml = h[:xml]
      @id = h[:id]
      @filename = h[:filename]
      @seq = h[:seq]
      @etyma = h[:etyma]
      @etyma_languages  = h[:etyma_languages]
      @etyma_xml = h[:etyma_xml]
      @form = Form.from_h(h[:form])
      @senses = h[:senses].map{|x| Sense.from_h(x)}
    end

  end

  class EntrySet
    include Enumerable
    def initialize
      @h = {}
    end

    def each
      return enum_for(:each) unless block_given?
      @h.values.each{|e| yield e}
    end

    def <<(e)
      @h[e.id] = e
    end

    def [](k)
      @h[k]
    end
  end
end
