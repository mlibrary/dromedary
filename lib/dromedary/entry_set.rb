require_relative 'entry'

module Dromedary
  class EntrySet
    include Enumerable
    def initialize
      @h = {}
    end

    def each
      return enum_for(:each) unless block_given?
      @h.values.each{|e| yield e}
    end

    def <<(e)
      @h[e.id] = e
    end

    # Look up by ID
    def [](k)
      @h[k]
    end

    # Load from <datapath>/json/<letters> all the entries that begin with the
    # given letter(s)
    #
    # @param [String] datapath The path to the `data` directory
    # @param [Array<String>, variable list of string] letters Load words that start with these letters
    # @return [EntrySet] self
    def load_by_letter(datapath, *letters)
      letters = letters.flatten
      datadir = Pathname(datapath)
      jsondir = datadir + 'json'
      alldirs     = Dir.new(jsondir).reject {|x| ['.', '..'].include? x}.map {|d| jsondir + d}.map(&:to_s).reject {|x| !File.directory?(x)}
      target_dirs = if letters.empty?
                      alldirs
                    else
                      regexps = letters.map {|x| Regexp.new("/#{x.upcase}*\\Z")}
                      alldirs.select {|d| regexps.any? {|r| r.match(d)}}
                    end
      target_dirs.each do |td|
        Dir.glob("#{td}/MED*.json") do |f|
          begin
            self << Dromedary::Entry.from_h(JSON.parse(File.read(f), symbolize_names: true))
          rescue => err
            $stderr.puts "Problem with #{f}: #{err}"
          end
        end
      end
      self
    end

    # Load all entries
    def load_all(datapath)
      load_by_letter(datapath, *('A'..'Z'))
    end
  end
end