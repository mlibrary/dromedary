require 'middle_english_dictionary'
require 'hanami/cli'
require 'concurrent'

module MedInstaller
  # Convert a bunch of Dromedary xml files into a more useful format.
  class Convert < Hanami::CLI::Command
    include  MedInstaller::Logger

    desc "Convert the xml files into (faster) json objects (takes a long time)"

    argument :datadir, required: true, desc: "The data directory. Converted files will be put in <datadir>/json"
    argument :dirname, required: false, desc: "one letter to convert"


    def new_pool
      threads = Concurrent.processor_count > 1 ? Concurrent.processor_count - 1 : 1
      Concurrent::ThreadPoolExecutor.new(
        min_threads:     threads,
        max_threads:     threads,
        max_queue:       100,
        fallback_policy: :caller_runs
      )
    end

    def find_oed_file(datapath)
      xmldir = datapath + 'xml'
      xmldir.children.select {|x| x.to_s =~ /MED2OED/}.first
    end

    def call(datadir:, dirname: '*')
      datapath = Pathname(datadir).realdirpath
      validate_xml_dir(datapath)

      pool = new_pool
      logger.info "Loading OED links so we can push them into entries"
      oed = MiddleEnglishDictionary::Collection::OEDLinkSet.from_xml_file(find_oed_file(datapath))
      letter = ''
      Dir.glob("#{datapath}/xml/#{dirname}/MED*xml").each_with_index do |filename, i|
        logger.info "#{i} done" if i > 0 and i % 2500 == 0
        basename, this_letter = letter_and_filename(filename)
        if this_letter != letter
          start_new_letter(datapath, this_letter)
          letter = this_letter
        end

        # pool.post do
          dump_json(datapath, filename, basename, oed)
        # end
      end

      pool.shutdown
      pool.wait_for_termination
    end


    private
    def dump_json(datapath, filename, basename, oed)
      entry          = MiddleEnglishDictionary::Entry.new_from_xml_file(filename)
      entry.oedlink = oed[entry.id]
      json_file_name = datapath + 'json' + "#{basename}.json"
      File.open(json_file_name, 'w:utf-8') {|out| out.puts entry.to_json}
    rescue => e
      puts e
      puts "Error in #{entry.source}"
      require 'pry'; binding.pry
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
