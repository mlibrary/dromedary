require 'zip'
require 'tmpdir'
require 'hanami/cli'

Zip.on_exists_proc = true

module MedInstaller
  class Extract < Hanami::CLI::Command
    include  MedInstaller::Logger

    desc "Extracts the individual xml files into <datadir>/xml/"

    argument :zipfile, required: true, desc: "The path to the zipfile (downloaded from Box)"
    argument :datadir, required: true, desc: "The data directory. XML files will be put in <datadir>/xml"
    example ["~/Downloads/In_progress_MEDC_files.zip ~/devel/med/data"]

    def logger
      MedInstaller::LOGGER
    end
    # The In_progress zip file is composed of other zip files and the DTDs/css
    # Take them in turn
    def call(zipfile:, datadir:)
      datapath = Pathname.new(datadir) + 'xml'
      datapath.mkpath
      Dir.mktmpdir do |tmpdir|

        zpath = Pathname.new(tmpdir) + 'med'
        zpath.mkpath

        Zip::File.open(zipfile) do |zip_file|
          zip_file.each do |entry|
            basename = entry.name.split('/').last
            if m = /MED_(.*?)\.zip\Z/.match(basename)
              zdest = (zpath + basename).to_s
              entry.extract(zdest)
              logger.info "Working on zip file #{basename}"
              letter       = m[1]
              data_sub_dir = datapath + letter
              data_sub_dir.mkpath
              Zip::File.open(zdest) do |inner_zip|
                inner_zip.each do |e|
                  bn       = e.name.split('/').last
                  filedest = (data_sub_dir + bn).to_s
                  e.extract(filedest)
                end
              end
            else
              logger.debug "Putting #{basename} in #{datapath}"
              entry.extract((datapath + basename).to_s)
            end
          end
        end
      end
    end
  end
end

