require 'middle_english_dictionary'
require 'hanami/cli'
require 'tempfile'

module MedInstaller
  # Convert a bunch of Dromedary xml files into a more useful format.
  class Convert < Hanami::CLI::Command
    include MedInstaller::Logger

    desc "Convert the xml files into (faster) json objects (takes a long time)"

    argument :datadir, required: true, desc: "The data directory. Converted files will be put in <datadir>/json"
    argument :letter, required: false, desc: "one letter to convert"


    def find_oed_file(datapath)
      xmldir = datapath + 'xml'
      xmldir.children.select {|x| x.to_s =~ /MED2OED/}.first
    end


    def call(datadir:, letter: nil)
      datapath = Pathname(datadir).realdirpath
      validate_xml_dir(datapath)

      tmpfile_name = Pathname(Dir.tmpdir) + 'entries.json.tmp'
      targetfile = if letter.nil?
                     datapath + 'entries.json'
                   else
                     datapath + "entries_#{letter}.json"
                   end
      outfile = File.open(tmpfile_name, 'w:utf-8')

      logger.info "Targeting #{targetfile}"
      oedfile = find_oed_file(datapath)
      logger.info "Loading OED links from #{oedfile} so we can push them into entries"
      oed    = MiddleEnglishDictionary::Collection::OEDLinkSet.from_xml_file(oedfile)
      count = 0
      Dir.glob("#{datapath}/xml/#{letter}*/MED*xml").each do |filename|
        count += 1
        logger.info "#{count} done" if count > 0 and count % 2500 == 0
        basename, this_letter = letter_and_filename(filename)
        if this_letter != letter
          start_new_letter(datapath, this_letter)
          letter = this_letter
        end

        entry = create_and_fill_entry(xmlfilepath: filename, oedlinks: oed)
        outfile.puts entry.to_json
      end
      logger.info "Finished converting #{count} entries."

      outfile.close

      logger.info "Copying temporary file to real location in #{datapath}"

      # Copy the tempfile over if we made it this far
      FileUtils.cp(tmpfile_name, targetfile)
    end


    private


      # @param [Pathname] xmlfilepath Path to the xml file being processed
      # @param [MiddleEnglishDictionary::Collection::OEDLinkSet] oedlinks
      # @return MiddleEnglishDictionary::Entry
      def create_and_fill_entry(xmlfilepath:, oedlinks:)
        entry         = MiddleEnglishDictionary::Entry.new_from_xml_file(xmlfilepath)
        entry.oedlink = oedlinks[entry.id]
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
