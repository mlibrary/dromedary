require 'dromedary/entry'
require 'hanami/cli'
require 'json'

Zip.on_exists_proc = true

module MedInstaller
  # Convert a bunch of Dromedary xml files into a more useful format.
  class Convert < Hanami::CLI::Command
    desc "Convert the xml files into (faster) json objects (takes a long time)"

    argument :datadir, required: true, desc: "The data directory. Converted files will be put in <datadir>/json"


    def logger
      MedInstaller::LOGGER
    end


    def call(datadir:)
      datapath = Pathname(datadir).realdirpath
      if Dir.exist?(datapath) and Dir.exist?(datapath + 'xml')
        logger.info "Found xml directory at #{datapath + 'xml'}"
      else
        raise "Can't find xml directory at #{datapath + 'xml'}. Exiting"
      end

      letter = ''
      Dir.glob("#{datapath}/xml/*/MED*xml").each_with_index do |f, i|
        logger.info "#{i} done" if i > 0 and i % 2500 == 0
        m           = %r(xml/((.*?)/(.*))\.xml\Z).match(f)
        this_letter = m[2]
        this_file   = m[1]
        if this_letter != letter
          logger.info "Beginning work on words starting with #{this_letter}"
          letter = this_letter
          jdir   = (datapath + 'json' + this_letter).to_s
          FileUtils.mkpath(mdir) unless File.exists? mdir
          FileUtils.mkpath(jdir) unless File.exists? jdir
        end

        entry = Dromedary::Entry.new(f)

        json_file_name = datapath + 'json' + "#{this_file}.json"
        File.open(json_file_name, 'w:utf-8') {|out| out.puts entry.to_h.to_json}
      end

      logger.info "Turning them all into one big file at #{datapath + 'all_entries.json'}"
      OneFile.new('onefile').call(datadir: datadir)
      logger.info "Finished"
    rescue => err
      logger.error err.message
      exit(1)
    end
  end

  # class OneFile < Hanami::CLI::Command
  #   desc "Turn all the individual .json files into one big .json file"
  #   argument :datadir, required: true, desc: "The data directory. Assumes files are in <datadir>/json"
  #
  #   def logger
  #     MedInstaller::LOGGER
  #   end
  #
  #
  #   def call(datadir:)
  #     datapath = Pathname(datadir).realdirpath
  #     logger.info "Beginning process of combining into all_entries.json"
  #
  #     entries = Dromedary::EntrySet.new
  #     letter = ''
  #     Dir.glob("#{datapath}/json/*/MED*.json").each_with_index do |f, i|
  #       logger.info "#{i} done" if i > 0 and i % 2500 == 0
  #       m           = %r(json/((.*?)/(.*))\.json\Z).match(f)
  #       this_letter = m[2]
  #       this_file   = m[1]
  #       if this_letter != letter
  #         logger.info "Loading words starting with #{this_letter}"
  #         letter = this_letter
  #       end
  #
  #       begin
  #         h = JSON.parse(File.read(f), symbolize_names: true)
  #         entries << Dromedary::Entry.from_h(h)
  #       rescue => err
  #         logger.warn "Skipping #{f} due to #{err.message}\n#{err.backtrace}"
  #       end
  #     end
  #
  #     logger.info "Got them all. Dumping all_entries.json"
  #     File.open(datapath + 'all_entries.json', 'w:utf-8') {|out| out.puts entries.map(&:to_h).to_json}
  #   end
  #
  #
  # end

end
