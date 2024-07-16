require "middle_english_dictionary"
require "hanami/cli"
require "tempfile"
require "zlib"
require "serialization/indexable_quote"
require_relative "../dromedary/services"

module MedInstaller
  # Convert a bunch of Dromedary xml files into a more useful format.
  class Convert < Hanami::CLI::Command
    include SemanticLogger::Loggable

    desc "[STEP 2 of 'prepare'] Convert the xml files into a (faster, more compact) json object (takes a long time)"

    option :build_directory,
      default: Dromedary::Services[:build_directory],
      desc: "The source data directory (contains 'xml' dir)"

    def most_recent_file(filenames)
      filenames.max { |a, b| File.mtime(a) <=> File.mtime(b) }
    end

    def find_oed_file(xmldir)
      candidates = xmldir.children.select { |x| x.to_s =~ /MED2OED/ }
      most_recent_file(candidates)
    end

    def find_doe_file(xmldir)
      candidates = xmldir.children.select { |x| x.to_s =~ /MED2DOE/ }.sort
      most_recent_file(candidates)
    end

    DIR_NAME_REGEX = Regexp.new "/([A-Z12][^/]*)/MED"

    def call(build_directory:)
      # @metrics = MiddleEnglishIndexMetrics.new({type: "convert_data"})
      Dromedary::Services.register(:build_directory) { build_directory }
      xmldir = Dromedary::Services.build_xml_directory

      validate_xml_dir(xmldir)
      entries_tmpfile = Pathname(Dir.tmpdir) + "entries.json.tmp"
      entries_outfile = Zlib::GzipWriter.open(entries_tmpfile)
      entries_targetfile = Dromedary::Services.entries_gz_file

      oedfile = find_oed_file(xmldir)
      logger.info "Loading OED links from #{oedfile} so we can push them into entries"
      oed = MiddleEnglishDictionary::Collection::OEDLinkSet.from_xml_file(oedfile)

      doefile = find_doe_file(xmldir)
      logger.info "Loading DOE links from #{doefile} so we can push them into entries, too"
      doe = MiddleEnglishDictionary::Collection::DOELinkSet.from_xml_file(doefile)

      count = 0
      current_directory = ""
      logger.info "Putting converted entries into temporary file #{entries_tmpfile}"
      Dir.glob("#{xmldir}/*/MED*xml").each do |filename|
        count += 1
        logger.info "#{count} done" if (count > 0) && (count % 2500 == 0)
        if File.empty?(filename)
          logger.error "File '#{filename}' is empty"
          # @metrics.log_error "File '#{filename}' is empty"
          next
        end
        current_directory = get_and_log_directory(filename, current_directory)

        entry = create_and_fill_entry(xmlfilepath: filename, oedlinks: oed, doelinks: doe)
        begin
          entries_outfile.puts entry.to_json unless entry == :bad_entry
        rescue => e
          logger.error e.full_message
          # @metrics.log_error(e.full_message)
        end
      end
      logger.info "Finished converting #{count} entries."

      # close the zipfiles
      entries_outfile.close

      logger.info "Copying temporary file to build directory at '#{entries_targetfile}'"

      # Copy the tempfile over if we made it this far
      FileUtils.cp(entries_tmpfile, entries_targetfile)

      logger.info "Creating the hyperbib mapping"
      create_hyperbib_mapping(build_directory: build_directory)
    end

    private

    def create_hyperbib_mapping(build_directory:)
      bib_all_file = Pathname.new(build_directory) + "xml" + "bib_all.xml"
      mapping_file = Pathname.new(build_directory) + "hyp_to_bibid.json"
      bibset = MiddleEnglishDictionary::Collection::BibSet.new(filename: bib_all_file)
      hyp_to_bibid = bibset.each_with_object({}) do |bib, acc|
        bib.hyps.each do |hyp|
          acc[hyp.delete("\\").upcase] = bib.id # TODO: Take out when backslashes removed from HYP ids
        end
      end
      File.open(mapping_file, "w:utf-8") do |out|
        out.puts hyp_to_bibid.to_json
      end
    end

    def get_and_log_directory(filename, current_directory)
      m = DIR_NAME_REGEX.match(filename)
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
      entry = MiddleEnglishDictionary::Entry.new_from_xml_file(xmlfilepath)
      entry.oedlinks = oedlinks[entry.id]
      entry.doelinks = doelinks[entry.id]
      entry
    rescue MiddleEnglishDictionary::FileNotFound,
      MiddleEnglishDictionary::FileEmpty,
      MiddleEnglishDictionary::InvalidXML => e
      logger.error e.message
      # @metrics.log_error(e.message)
      :bad_entry
    rescue => e
      logger.error e.full_message
      # @metrics.log_error(e.full_message)
      raise e
    end

    def start_new_letter(datapath, this_letter)
      logger.info "Beginning work on words starting with #{this_letter}"
    end

    def letter_and_filename(f)
      m = %r{(/(.*?)/(.*))\.xml\Z}.match(f)
      this_letter = m[2]
      this_file = m[1]
      [this_file, this_letter]
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
