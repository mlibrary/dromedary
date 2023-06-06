require 'faraday'

class SolrHelper
  def self.blacklight_solr_url
    "#{ENV['SOLR_URL']}/#{ENV['SOLR_COLLECTION']}"
  end

  def self.solr_collection
    solr_url = ENV["SOLR_URL"]
    collection_name = ENV["SOLR_COLLECTION"]
    client = Client.new(solr_url)
    client.collection(collection_name)
  end

  # standard:disable Lint/DuplicateMethods
  attr_accessor :data_dir

  def self.data_dir=(path)
    @data_dir = Pathname.new(path).realpath
  end

  def self.data_dir
    @data_dir || live_data_dir
  end
  # standard:enable  Lint/DuplicateMethods

  def self.live_data_dir
    Pathname.new(Dromedary.config.data_dir).realpath
    path = ENV['DATA_DIR'] || "./data/"
    Pathname.new(path).realpath
  end

  def self.solr_config_dir
    path = ENV['SOLR_CONFIG_DIR'] || "./solr/med/"
    Pathname.new(path).realpath
  end

  def self.solr_libs_dir
    path = ENV['SOLR_LIBS_DIR'] || "./solr/lib/"
    Pathname.new(path).realpath
  end

  def self.dot_solr
    path = ENV['DOT_SOLR'] || "./.solr/"
    Pathname.new(path).realpath
  end

  def self.index_dir
    path = ENV['INDEX_DIR'] || "./indexer/"
    Pathname.new(path).realpath
  end

  def self.entries_path
    data_dir + "entries.json.gz"
  end

  def self.bibfile_path
    data_dir + "bib_all.xml"
  end

  def self.hyp_to_bibid_path
    data_dir + "hyp_to_bibid.json"
  end

  class Client
    def initialize(solr_url)
      @solr_connection = Faraday.new(
        url: solr_url
      ) do |conn|
        conn.request :authorization, :basic, ENV['SOLR_USER'], ENV['SOLR_PASSWORD']
        conn.response :json
      end
    end

    def collection(collection_name)
      raise "Collection #{collection_name} not found" unless collections.include? collection_name.to_s
      Collection.new(@solr_connection, collection_name.to_s)
    end

    def collections
      response = get('admin/collections', {action: 'LIST'})
      response['collections']
    end

    def get(path, args = {})
      response = @solr_connection.get(path, args)
      json_response = response.body
      if json_response['error']
        raise RuntimeError.new, json_response['error']
      end
      json_response
    end

    def post_json(path, object_to_post)
      response = @solr_connection.post(path, JSON.dump(object_to_post), {'Content-type' => 'application/json'})
      json_response = response.body
      puts json_response.inspect
      if json_response['error']
        raise RuntimeError.new, json_response['error']
      end
      json_response
    end

    class Collection
      attr_accessor :solr_connection, :collection_name

      def initialize(solr_connection, collection_name)
        @solr_connection = solr_connection
        @collection_name = collection_name
      end

      def new_collection_name
        "#{collection_name}_new"
      end

      def create_new
        @solr_connection.post(
          ["admin/collections?action=CREATE",
           "&name=#{new_collection_name}",
           "&collection.configName=#{collection_name}",
           "&numShards=1"].join("")
         )
      end

      def get(path, args = {})
        response = @solr_connection.get(path, args)
        json_response = response.body
        if json_response['error']
          raise RuntimeError.new, json_response['error']
        end
        json_response
      end

      def post_json(path, object_to_post)
        response = @solr_connection.post(path, JSON.dump(object_to_post), {'Content-type' => 'application/json'})
        json_response = response.body
        puts json_response.inspect
        if json_response['error']
          raise RuntimeError.new, json_response['error']
        end
        json_response
      end

      def commit
        update({'commit' => {}}, new_collection_name)
      end

      def optimize
        update({'optimize' => {}}, new_collection_name)
      end

      def update(object_to_post, url_infix)
        post_json("#{url_infix}/update",  object_to_post)
      end
    end

  end
end
