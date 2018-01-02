
require 'hanami/cli'
module MedInstaller
  class Usage < Hanami::CLI::Command

    def call(error = '')
      puts <<~USAGE_MESSAGE

        #{error}

                  install_data -- unzip and transform the data from a raw zip file

                  USAGE
                  bin / install_data < /path/ to / In_progress_MEC_files.zip > < /path/ to / datadir >

                    EFFECTS
                  Unzips the In_progress_MEC_files.zip into component zips
                  Puts them all, broken down by letter(s) into < datadir > /xml/
                  Transforms all of *those * and marshals to < datadir > /marshal/
                  Creates a Dromedary::Entry::EntrySet marshaled to < datadir > /all_entries.marshal

      USAGE_MESSAGE
    end
  end

  class Checkargs
    def checkargs(zipfile, datadir)
      unless datadir and zipfile
        usage
        exit(1)
      end

      unless Dir.exist? datadir
        usage("Directory #{datadir} does not exist")
        exit(1)
      end

      unless File.exist? zipfile
        usage("#{zipfile} does not exist")
        exit(1)
      end

    end
  end
end
