require 'dromedary/entry'
require 'hanami/cli'

Zip.on_exists_proc = true

module MedInstaller
  # Convert a bunch of Dromedary xml files into a more useful format.
  class Convert < Hanami::CLI::Command
    desc "Convert the xml files into (faster) marshaled objects"

    argument :datadir, required: true, desc: "The data directory. Converted files will be put in <datadir>/marshal"


    def logger
      MedInstaller::LOGGER
    end



    def call(datadir:)
      datapath      = Pathname(datadir).realdirpath
      if Dir.exist?(datapath) and Dir.exist?(datapath + 'xml')
        logger.info "Found xml directory at #{datapath + 'xml'}"
      else
        raise "Can't find xml directory at #{datapath + 'xml'}. Exiting"
      end

      marshal_files = Hash.new {|h, k| h[k] = []}
      letter        = ''
      Dir.glob("#{datapath}/xml/*/MED*xml").each do |f|
        m           = %r(xml/((.*?)/(.*))\.xml\Z).match(f)
        this_letter = m[2]
        this_file   = m[1]
        if this_letter != letter
          logger.info "Beginning work on words starting with #{this_letter}"
          letter = this_letter
          mdir = (datapath + "marshal" + this_letter).to_s
          FileUtils.mkpath(mdir) unless File.exists? mdir
        end

        marshal_file_name = datapath + "marshal" + "#{this_file}.marshal"
        Marshal.dump(Dromedary::Entry.new(f), File.open(marshal_file_name, 'wb'))
        marshal_files[this_letter] << marshal_file_name
      end

      logger.info "Beginning process of combining into all_entries.marshal"

      entries = Dromedary::EntrySet.new
      marshal_files.each_pair do |letter, filenames|
        $stderr.puts letter
        filenames.each do |f|
          begin
            entries << Marshal.load(File.open(f, 'rb'))
          rescue => err
            logger.warn "Skipping #{f} due to #{err.message}\n#{err.backtrace}"
          end
        end
      end

      logger.info "Got them all. Dumping all_entries.marshal"

      Marshal.dump(entries, File.open(datapath + 'all_entries.marshal', 'wb'))



    rescue => err
        logger.error err.message
        exit(1)
    end
  end
end
