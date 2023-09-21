require "simple_solr_client"
require "faraday"

# standard:disable Lint/UnreachableCode

module MySimpleSolrClient
  # A Client talks to the Solr instance; use a SimpleSolrClient::Core to talk to a
  # particular core.

  class Client
    attr_reader :base_url, :rawclient, :solr_connection

    def initialize(url)
      # puts "initialize(#{url})"
      @base_url = url.chomp("/")
      # puts "@base_url = #{base_url}"
      @client_url = @base_url
      @rawclient = HTTPClient.new
      @solr_connection = Faraday.new(
        url: url
      ) do |conn|
        conn.request :authorization, :basic, Dromedary::Services[:solr_username], Dromedary::Services[:solr_password]
        conn.response :json
      end

      # raise "Can't connect to Solr at #{url}" unless self.up?
    end

    # Construct a URL for the given arguments that hit the configured solr
    # @return [String] the new url, based on the base_url and the passed args
    def url(*args)
      raise "Not Implemented Yet"

      [@base_url, *args].join("/").chomp("/")
    end

    # Sometimes, you just gotta have a top_level_url (as opposed to a
    # core-level URL)
    def top_level_url(*args)
      [@client_url, *args].join("/").chomp("/")
    end

    def ping
      raise "Not Implemented Yet"

      get("admin/ping")
    end

    # Get info about the solr system itself
    def system
      raise "Not Implemented Yet"

      @system ||= SimpleSolrClient::System.new(get("admin/info/system"))
    end

    # @return [String] The solr semver version
    def version
      raise "Not Implemented Yet"

      system.solr_semver_version
    end

    # @return [Integer] the solr major version
    def major_version
      raise "Not Implemented Yet"

      system.solr_major_version
    end

    # Is the server up (and responding to a ping?)
    # @return [Boolean]
    def up?
      res = get("api", {force_top_level_url: true})
      # puts res.inspect
      # puts res['responseHeader']['status'] == 0
      res["responseHeader"]["status"] == 0
    rescue
      false
    end

    # Call a 'get' on the underlying http client and return the content
    # Will use whatever the URL is for the current context ("client" or
    # "core"), although you can pass in :force_top_level=>true for those
    # cases when you absolutely have to use the client-level url and not a
    # core level URL
    #
    # Error handling? What error handling???
    def raw_get_content(path, args = {})
      u = if args.delete(:force_top_level_url)
        top_level_url(path)
      else
        url(path)
      end
      # puts "@rawclient.get(#{u}, #{args})"
      # res = @rawclient.get(u, args)
      # res.content
      puts "@solr_connection.get(#{u}, #{args})"
      res = @solr_connection.get(u, args)
      res.body
    end

    # A basic get to the instance (not any specific core)
    # @param [String] path The parts of the URL that comes after the core
    # @param [Hash] args The url arguments
    # @return [Hash] the parsed-out response
    def _get(path, args = {})
      path.sub!(/\A\//, "")
      args["wt"] = "json"
      # puts path
      # res = JSON.parse(raw_get_content(path, args))
      res = raw_get_content(path, args)
      if res["error"]
        raise RuntimeError.new, res["error"]
      end
      res
    end

    #  post JSON data.
    # @param [String] path The parts of the URL that comes after the core
    # @param [Hash,Array] object_to_post The data to post as json
    # @return [Hash] the parsed-out response

    def _post_json(path, object_to_post)
      # puts "@rawclient.post(#{url(path)}, #{JSON.dump(object_to_post), {'Content-type' => 'application/json'})"
      # resp = @rawclient.post(url(path), JSON.dump(object_to_post), {'Content-type' => 'application/json'})
      # JSON.parse(resp.content)
      puts "@solr_connection.post(#{url(path)}, #{JSON.dump(object_to_post)}, {'Content-type' => 'application/json'})"
      resp = @solr_connection.post(url(path), JSON.dump(object_to_post), {"Content-type" => "application/json"})
      # JSON.parse(resp.body)
      resp.body
    end

    # Get from solr, and return a Response object of some sort
    # @return [SimpleSolrClient::Response, response_type]
    def get(path, args = {}, response_type = nil)
      response_type = SimpleSolrClient::Response::GenericResponse if response_type.nil?
      response_type.new(_get(path, args))
    end

    # Post an object as JSON and return a Response object
    # @return [SimpleSolrClient::Response, response_type]
    def post_json(path, object_to_post, response_type = nil)
      response_type = SimpleSolrClient::Response::GenericResponse if response_type.nil?
      response_type.new(_post_json(path, object_to_post))
    end

    # Get a client specific to the given core2
    # @param [String] corename The name of the core (which must already exist!)
    # @return [SimpleSolrClient::Core]
    def core(corename)
      raise "Core #{corename} not found" unless cores.include? corename.to_s
      MySimpleSolrClient::Core.new(@base_url, corename.to_s)
    end

    # Get all the cores
    def cores
      cdata = get("api/collections", {force_top_level_url: true})
      # puts cdata.inspect
      # puts cdata['collections']
      cdata["collections"]
    end

    # Create a new, temporary core
    # noinspection RubyWrongHash
    def new_core(corename)
      raise "Not Implemented Yet"

      dir = temp_core_dir_setup(corename)

      args = {
        wt: "json",
        action: "CREATE",
        name: corename,
        instanceDir: dir
      }

      get("admin/cores", args)
      core(corename)
    end

    def temp_core
      raise "Not Implemented Yet"

      new_core("sstemp_" + SecureRandom.uuid)
    end

    # Set up files for a temp core
    def temp_core_dir_setup(corename)
      raise "Not Implemented Yet"

      dest = Dir.mktmpdir("simple_solr_#{corename}_#{SecureRandom.uuid}")
      src = SAMPLE_CORE_DIR
      FileUtils.cp_r File.join(src, "."), dest
      dest
    end

    # Unload all cores whose name includes 'sstemp'
    def unload_temp_cores
      raise "Not Implemented Yet"

      cores.each do |k|
        core(k).unload if /sstemp/.match?(k)
      end
    end
  end

  class Core < Client
    include SimpleSolrClient::Core::Admin

    # Reload the core (for when you've changed the schema, solrconfig, synonyms, etc.)
    # Make sure to mark the schema as dirty!
    # @return self
    def reload
      post_json("", {reload: {}})
      self
    end

    include SimpleSolrClient::Core::CoreData
    include SimpleSolrClient::Core::Index
    include SimpleSolrClient::Core::Search

    attr_reader :core
    alias_method :name, :core

    def initialize(url, core = nil)
      if core.nil?
        puts "url: #{url}"
        components = url.gsub(%r{/\Z}, "").split("/")
        puts "components: #{components}"
        core = components.last
        puts "core: #{core}"
        url = components[0..-2].join("/")
        puts "url: #{url}"
      end
      # puts "url: #{url}"
      super(url)
      # puts "core: #{core}"
      @core = core
    end

    # Override #url so we're now talking to the core
    def url(*args)
      [@base_url, "api", "c", @core, *args].join("/").chomp("/")
      # puts rv
    end

    # Send JSON to this core's update/json handler
    def update(object_to_post, response_type = nil)
      post_json("update/json", object_to_post, response_type)
    end
  end
end

# standard:enable Lint/UnreachableCode
