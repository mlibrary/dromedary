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
    end

  end
end
