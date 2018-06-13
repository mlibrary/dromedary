require 'middle_english_dictionary'
require 'hanami/cli'
require 'tempfile'
require 'zlib'
require 'serialization/indexable_quote'

module MedInstaller
  # Convert a bunch of Dromedary xml files into a more useful format.
  class Convert < Hanami::CLI::Command
    include MedInstaller::Logger

    desc "Convert the xml files into a (faster, more compact) json object (takes a long time)"

    argument :datadir, required: true, desc: "The data directory. Converted files will be <datadir>/entries.json.gz"
    argument :letter, required: false, desc: "one letter to convert"


    def most_recent_file(filenames)
      filenames.sort {|a, b| File.mtime(a) <=> File.mtime(b)}.last
    end

    def find_oed_file(datapath)
      xmldir     = datapath + 'xml'
      candidates = xmldir.children.select {|x| x.to_s =~ /MED2OED/}
      most_recent_file(candidates)
    end

    def find_doe_file(datapath)
      xmldir     = datapath + 'xml'
      candidates = xmldir.children.select {|x| x.to_s =~ /MED2DOE/}.sort
      most_recent_file(candidates)
    end


    DIR_NAME_REGEX = Regexp.new "/xml/([A-Z12][^/]*)/MED"


    def call(datadir:, letter: nil)
      datapath = Pathname(datadir).realdirpath
      validate_xml_dir(datapath)

      entries_tmpfile_name = Pathname(Dir.tmpdir) + 'entries.json.tmp'
      quotes_tmpfile_name  = Pathname(Dir.tmpdir) + 'quotes.json.tmp'

      logger.info "letter is #{letter}"
      if letter.nil?
        entries_targetfile = datapath + 'entries.json.gz'
        quotes_targetfile  = datapath + 'quotes.json.gz'
      else
        entries_targetfile = datapath + "entries_#{letter}.json.gz"
        quotes_targetfile  = datapath + "quotes_#{letter}.json.gz"
      end

      entries_outfile = Zlib::GzipWriter.open(entries_tmpfile_name)
      quotes_outfile  = Zlib::GzipWriter.open(quotes_tmpfile_name)

      logger.info "Targeting #{entries_targetfile}"

      oedfile = find_oed_file(datapath)
      logger.info "Loading OED links from #{oedfile} so we can push them into entries"
      oed = MiddleEnglishDictionary::Collection::OEDLinkSet.from_xml_file(oedfile)

      doefile = find_doe_file(datapath)
      logger.info "Loading DOE links from #{doefile} so we can push them into entries, too"
      doe = MiddleEnglishDictionary::Collection::DOELinkSet.from_xml_file(doefile)

      count             = 0
      current_directory = ''
      Dir.glob("#{datapath}/xml/#{letter}*/MED*xml").each do |filename|
        count += 1
        logger.info "#{count} done" if count > 0 and count % 2500 == 0
        if File.empty?(filename)
          logger.error "File '#{filename}' is empty"
          next
        end
        current_directory = get_and_log_directory(filename, current_directory)

        entry = create_and_fill_entry(xmlfilepath: filename, oedlinks: oed, doelinks: doe)
        begin
          entries_outfile.puts entry.to_json
          entry.all_citations.each do |cite|
            quotes_outfile.puts Dromedary::IndexableQuote.new(citation: cite).to_json
          end
        rescue => e
          require 'pry'; binding.pry
        end
      end
      logger.info "Finished converting #{count} entries."

      #close the zipfiles
      entries_outfile.close
      quotes_outfile.close


      logger.info "Copying temporary files to real location at '#{datapath}'"

      # Copy the tempfile over if we made it this far
      FileUtils.cp(entries_tmpfile_name, entries_targetfile)
      FileUtils.cp(quotes_tmpfile_name, quotes_targetfile)
    end


    private


    def get_and_log_directory(filename, current_directory)
      m       = DIR_NAME_REGEX.match(filename)
      dirname = m[1]

      if dirname != current_directory
        logger.info "Starting on #{dirname}"
        dirname
      else
        current_directory
      end
    end


    # @param [Pathname] xmlfilepath Path to the xml file being processed
    # @param [MiddleEnglishDictionary::Collection::OEDLinkSet] oedlinks
    # @return MiddleEnglishDictionary::Entry
    def create_and_fill_entry(xmlfilepath:, oedlinks:, doelinks:)
      entry          = MiddleEnglishDictionary::Entry.new_from_xml_file(xmlfilepath)
      entry.oedlinks = oedlinks[entry.id]
      entry.doelinks = doelinks[entry.id]
      entry
    rescue MiddleEnglishDictionary::FileNotFound,
      MiddleEnglishDictionary::FileEmpty,
      MiddleEnglishDictionary::InvalidXML => e
      logger.error e.message
    rescue => e
      puts e
      require 'pry'; binding.pry
      puts "Error in #{entry.source}"
    end


    def start_new_letter(datapath, this_letter)
      logger.info "Beginning work on words starting with #{this_letter}"
      jdir = (datapath + 'json' + this_letter).to_s
      FileUtils.mkpath(jdir) unless File.exists? jdir
    end


    def letter_and_filename(f)
      m           = %r(xml/((.*?)/(.*))\.xml\Z).match(f)
      this_letter = m[2]
      this_file   = m[1]
      return this_file, this_letter
    end


    def validate_xml_dir(datapath)
      if Dir.exist?(datapath) and Dir.exist?(datapath + 'xml')
        logger.info "Found xml directory at #{datapath + 'xml'}"
      else
        raise "Can't find xml directory at #{datapath + 'xml'}. Exiting"
      end
    end
  end
end
