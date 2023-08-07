require "zip"
require "tmpdir"
require "hanami/cli"
require_relative "../../config/load_local_config"
require_relative "services"

Zip.on_exists_proc = true

module MedInstaller
  class Extract < Hanami::CLI::Command
    include MedInstaller::Logger

    desc "Extracts the individual xml files into <datadir>/xml/"

    argument :zipfile, required: true, desc: "The path to the zipfile (downloaded from Box)"
    argument :build_directory,
      required: false,
      default: Services[:build_directory],
      desc: "The build directory. XML files will be put in <datadir>/xml"
    example ["~/Downloads/In_progress_MEDC_files.zip ~/devel/med/data/build_20230101"]

    # The In_progress zip file is composed of other zip files and the DTDs/css
    # Take them in turn
    def call(zipfile:, build_directory:)
      build_path = Pathname.new(build_directory) + "xml"
      build_path.mkpath

      raise ArgumentError.new("Zipfile #{zipfile} not found") unless Pathname.new(zipfile).exist?
      raise ArgumentError.new("Zipfile #{zipfile} not readable") unless Pathname.new(zipfile).readable?
      raise ArgumentError.new("Zipfile #{zipfile} not readable") unless Pathname.new(zipfile).readable?

      logger.info "Extract: read from #{zipfile}, target #{build_path}"
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
              extract_entries(basename, build_path, entry, first_letter_of_dir, zpath)
            when "LINKS_done.zip"
              extract_links(basename, build_path, zpath, entry)
            else
              logger.debug "Putting #{basename} in #{build_path}"
              entry.extract((build_path + basename).to_s)
            end
          end
        end
      end
    end

    private

    def extract_links(basename, datapath, zpath, entry)
      zdest = (zpath + basename).to_s
      entry.extract(zdest)
      logger.info "Extracting links from #{basename}"
      data_sub_dir = datapath + "links"
      data_sub_dir.mkpath
      extract_into(data_sub_dir, zdest)
    end

    def extract_entries(basename, datapath, entry, letter_dir_name, zpath)
      zdest = (zpath + basename).to_s
      entry.extract(zdest)
      logger.info "Working on zip file #{basename}"
      data_sub_dir = datapath + letter_dir_name
      data_sub_dir.mkpath
      extract_into(data_sub_dir, zdest)
    end

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
