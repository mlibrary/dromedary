module MedInstaller
  module HypToBibId
    
    def self.load_from_file!(filename)
      target = Pathname(filename)
      raise Errno::ENOENT.new("Can't find #{target}") unless target.exist?
      JSON.parse(File.read(target))
    end
    
    # @param collection [SolrCloud::Collection]
    # @param data [Hash] the hyp_to_bibid hash
    def self.dump_file_to_solr(collection:, filename:)
      data = File.read(filename)
      doc = { id: "hyp_to_bibid", hyp_to_bibid: data}
      collection.add(doc)
      collection.commit(hard: true)
    end

    # Messy, but gets the job done
    # @param collection [SolrCloud::Collection]
    # @return [Hash] the hyp_to_bibid hash
    def self.get_from_solr(collection:)
      hyp_handler = "solr/#{collection.name}/hyp_to_bibid"
      resp = collection.get(hyp_handler)
      doc = resp.body["response"]["docs"].first
      JSON.parse(doc["hyp_to_bibid"])
    end
    
  end
end