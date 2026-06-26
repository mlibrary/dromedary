require "zip"
require "tmpdir"
require "hanami/cli"
# require_relative "../../config/load_local_config"
require_relative "../dromedary/services"
require "semantic_logger"

Zip.on_exists_proc = true

module MedInstaller
  class Extract < Hanami::CLI::Command
    # include MedInstaller::Logger
    include SemanticLogger::Loggable

    desc "[STEP 1 of 'prepare'] Extract the individual xml files into <datadir>/xml/"

    argument :zipfile, required: true, desc: "The path to the zipfile (downloaded from Box)"
    argument :build_directory,
      required: false,
      default: Dromedary::Services[:build_directory],
      desc: "The build directory. XML files will be put in <build_directory>/xml"

    # Extracts MED XML files from a nested zip archive into a build directory.
    #
    # The top-level zip contains per-letter entry zips (+MED_<letter>.zip+),
    # a links zip (+LINKS_done.zip+), and DTD/CSS files. Each sub-zip is
    # extracted into its own subdirectory under +<build_directory>/xml/+.
    #
    # @param zipfile [String, Pathname] path to the top-level zip from Box
    # @param build_directory [String, Pathname] destination; XML files go in
    #   +<build_directory>/xml/+
    # @return [void]
    # @raise [ArgumentError] if +zipfile+ does not exist or is not readable
    def call(zipfile:, build_directory:)
      xmldir = Pathname.new(build_directory) + "xml"
      if xmldir.exist?
        logger.warn "#{xmldir} exists; data will be overwritten"
      end
      xmldir.mkpath

      raise ArgumentError.new("Zipfile #{zipfile} not found") unless Pathname.new(zipfile).exist?
      raise ArgumentError.new("Zipfile #{zipfile} not readable") unless Pathname.new(zipfile).readable?
      raise ArgumentError.new("Zipfile #{zipfile} not readable") unless Pathname.new(zipfile).readable?

      logger.info "Extract: read from #{zipfile}, target #{xmldir}"
      Dir.mktmpdir do |tmpdir|
        zpath = Pathname.new(tmpdir) + "med"
        zpath.mkpath

        matches_zipfile_for_entries = /MED_(.*?)\.zip\Z/

        Zip::File.open(zipfile) do |zip_file|
          zip_file.each do |entry|
            basename = entry.name.split("/").last

            case basename
            when matches_zipfile_for_entries
              m = matches_zipfile_for_entries.match(basename)
              first_letter_of_dir = m[1]
              extract_entries(basename, xmldir, entry, first_letter_of_dir, zpath)
            when "LINKS_done.zip"
              extract_links(basename, xmldir, zpath, entry)
            else
              logger.debug "Putting #{basename} in #{xmldir}"
              entry.extract((xmldir + basename).to_s)
            end
          end
        end
      end
    end

    private

    # Extracts the +LINKS_done.zip+ sub-archive into +<datapath>/links/+.
    # @param basename [String] filename of the links zip
    # @param datapath [Pathname] destination XML directory
    # @param zpath [Pathname] temp directory for intermediate extraction
    # @param entry [Zip::Entry] the zip entry to extract from
    # @return [void]
    def extract_links(basename, datapath, zpath, entry)
      zdest = (zpath + basename).to_s
      entry.extract(zdest)
      logger.info "Extracting links from #{basename}"
      data_sub_dir = datapath + "links"
      data_sub_dir.mkpath
      extract_into(data_sub_dir, zdest)
    end

    # Extracts a per-letter entry zip into +<datapath>/<letter_dir_name>/+.
    # @param basename [String] filename of the letter zip (e.g. +MED_A.zip+)
    # @param datapath [Pathname] destination XML directory
    # @param entry [Zip::Entry] the zip entry to extract from
    # @param letter_dir_name [String] subdirectory name derived from the letter (e.g. +"A"+)
    # @param zpath [Pathname] temp directory for intermediate extraction
    # @return [void]
    def extract_entries(basename, datapath, entry, letter_dir_name, zpath)
      zdest = (zpath + basename).to_s
      entry.extract(zdest)
      logger.info "Working on zip file #{basename}"
      data_sub_dir = datapath + letter_dir_name
      data_sub_dir.mkpath
      extract_into(data_sub_dir, zdest)
    end

    # Extracts all entries from a zip file into +data_sub_dir+.
    # @param data_sub_dir [Pathname] destination directory
    # @param zdest [String] path to the zip file to extract
    # @return [void]
    def extract_into(data_sub_dir, zdest)
      Zip::File.open(zdest) do |inner_zip|
        inner_zip.each do |e|
          bn = e.name.split("/").last
          filedest = (data_sub_dir + bn).to_s
          e.extract(filedest)
        end
      end
    end
  end
end
