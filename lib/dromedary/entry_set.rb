require_relative 'entry'

module Dromedary
  class EntrySet
    include Enumerable

    attr_accessor :target_dirs

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
      alldirs = Dir.new(jsondir).to_a.reject {|x| ['.', '..'].include? x}.select{|x| File.directory?(jsondir + x) and x =~ /\A[A-Z]/}
      target_dirs = if letters.empty?
                      alldirs
                    else
                      regexps = letters.map {|x| Regexp.new("\\A#{x.upcase}.*\\Z")}
                      alldirs.select {|d| regexps.any? {|r| r.match(d)}}
                    end
      @target_dirs = target_dirs
      target_dirs.each do |td|
        dir = jsondir + td
        Dir.glob("#{dir}/MED*.json") do |f|
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
