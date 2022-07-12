require 'middle_english_dictionary'
require 'hanami/cli'
require 'tempfile'
require 'zlib'
require 'serialization/indexable_quote'
require 'annoying_utilities'


module MedInstaller
  # Convert a bunch of Dromedary xml files into a more useful format.
  class Convert < Hanami::CLI::Command
    include MedInstaller::Logger

    desc "Convert the xml files into a (faster, more compact) json object (takes a long time)"

    argument :source_dir, required: true, desc: "The source data directory (something/xml/)"

    class YabedaHelper

      attr_accessor :enabled

      def initialize
        @enabled = false
        if ENV['PROMETHEUS_PUSH_GATEWAY']
          @enabled = true
        end
      end

      def configure!
        if enabled
          Yabeda.configure do
            group :convert_data do
              gauge :error, tags: :err_msg, comment: "an error occuring in convert_data"
            end
          end

          Yabeda.configure!
        end
      end

      def log_error(err)
        if enabled
          Yabeda.convert_data.error.set({err_msg: err}, Time.now.to_i)
          Yabeda::Prometheus.push_gateway.add(Yabeda::Prometheus.registry)
        end
      end

    end

    def most_recent_file(filenames)
      filenames.sort {|a, b| File.mtime(a) <=> File.mtime(b)}.last
    end

    def find_oed_file(xmldir)
      candidates = xmldir.children.select {|x| x.to_s =~ /MED2OED/}
      most_recent_file(candidates)
    end

    def find_doe_file(xmldir)
      candidates = xmldir.children.select {|x| x.to_s =~ /MED2DOE/}.sort
      most_recent_file(candidates)
    end


    DIR_NAME_REGEX = Regexp.new "/([A-Z12][^/]*)/MED"


    def call(source_dir:)
      @helper = YabedaHelper.new
      @helper.configure!

      source_data_path = Pathname(source_dir).realdirpath

      validate_xml_dir(source_data_path)

      logger.info "Will put finished file in #{AnnoyingUtilities.entries_path}"

      entries_tmpfile = Pathname(Dir.tmpdir) + 'entries.json.tmp'
      entries_outfile = Zlib::GzipWriter.open(entries_tmpfile)

      entries_targetfile =  AnnoyingUtilities.data_dir + 'entries.json.gz'

      oedfile = find_oed_file(source_data_path)
      logger.info "Loading OED links from #{oedfile} so we can push them into entries"
      oed = MiddleEnglishDictionary::Collection::OEDLinkSet.from_xml_file(oedfile)

      doefile = find_doe_file(source_data_path)
      logger.info "Loading DOE links from #{doefile} so we can push them into entries, too"
      doe = MiddleEnglishDictionary::Collection::DOELinkSet.from_xml_file(doefile)

      count             = 0
      current_directory = ''
      Dir.glob("#{source_data_path}/*/MED*xml").each do |filename|
        count += 1
        logger.info "#{count} done" if count > 0 and count % 2500 == 0
        if File.empty?(filename)
          logger.error "File '#{filename}' is empty"
          @helper.log_error "File '#{filename}' is empty"
          next
        end
        current_directory = get_and_log_directory(filename, current_directory)

        entry = create_and_fill_entry(xmlfilepath: filename, oedlinks: oed, doelinks: doe)
        begin
          entries_outfile.puts entry.to_json unless entry == :bad_entry
        rescue => e
          logger.error e.full_message
          @helper.log_error(e.full_message)
        end
      end
      logger.info "Finished converting #{count} entries."

      #close the zipfiles
      entries_outfile.close


      logger.info "Copying temporary file to real location at '#{entries_targetfile}'"

      # Copy the tempfile over if we made it this far
      FileUtils.cp(entries_tmpfile, entries_targetfile)
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
      @helper.log_error(e.message)
      return :bad_entry
    rescue => e
      logger.error e.full_message
      @helper.log_error(e.full_message)
      raise e
    end


    def start_new_letter(datapath, this_letter)
      logger.info "Beginning work on words starting with #{this_letter}"
    end


    def letter_and_filename(f)
      m           = %r((/(.*?)/(.*))\.xml\Z).match(f)
      this_letter = m[2]
      this_file   = m[1]
      return this_file, this_letter
    end


    def validate_xml_dir(xmldir)
      if Dir.exist?(xmldir)
        logger.info "Found xml directory at #{xmldir}"
      else
        raise "Can't find xml directory at #{xmldir}. Exiting"
      end
    end
  end
end
