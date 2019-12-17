require 'zip'
require 'tmpdir'
require 'hanami/cli'
require_relative '../../config/load_local_config'

Zip.on_exists_proc = true

module MedInstaller
  class Extract < Hanami::CLI::Command
    include MedInstaller::Logger

    desc "Extracts the individual xml files into <datadir>/xml/"

    argument :zipfile, required: true, desc: "The path to the zipfile (downloaded from Box)"
    argument :datadir,
             required: false,
             default:Pathname.new(Dromedary.config.build_dir).realdirpath,
             desc: "The data directory. XML files will be put in <datadir>/xml"
    example ["~/Downloads/In_progress_MEDC_files.zip ~/devel/med/data"]

    # The In_progress zip file is composed of other zip files and the DTDs/css
    # Take them in turn
    def call(zipfile:, datadir:)
      datapath = Pathname.new(datadir) + 'xml'
      datapath.mkpath

      raise ArgumentError.new("Zipfile #{zipfile} not found") unless Pathname.new(zipfile).exist?
      raise ArgumentError.new("Zipfile #{zipfile} not readable") unless Pathname.new(zipfile).readable?
      raise ArgumentError.new("Zipfile #{zipfile} not readable") unless Pathname.new(zipfile).readable?

      logger.info "Extract: read from #{zipfile}, target #{datapath}"
      Dir.mktmpdir do |tmpdir|

        zpath = Pathname.new(tmpdir) + 'med'
        zpath.mkpath

        matches_zipfile_for_entries = /MED_(.*?)\.zip\Z/

        Zip::File.open(zipfile) do |zip_file|
          zip_file.each do |entry|
            basename = entry.name.split('/').last

            case basename
            when matches_zipfile_for_entries
              m                   = matches_zipfile_for_entries.match(basename)
              first_letter_of_dir = m[1]
              extract_entries(basename, datapath, entry, first_letter_of_dir, zpath)
            when "LINKS_done.zip"
              extract_links(basename, datapath, zpath, entry)
            else
              logger.debug "Putting #{basename} in #{datapath}"
              entry.extract((datapath + basename).to_s)
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
      data_sub_dir = datapath + 'links'
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
          bn       = e.name.split('/').last
          filedest = (data_sub_dir + bn).to_s
          e.extract(filedest)
        end
      end
    end
  end
end

