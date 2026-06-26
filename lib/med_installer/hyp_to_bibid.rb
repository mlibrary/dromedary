module MedInstaller
  # Utility module for loading and persisting the HYP-ID-to-bib-ID mapping.
  #
  # MED entries reference bibliography records via "HYP" identifiers (RIDs).
  # This mapping is built once during the convert step and then uploaded to Solr
  # as a special document so it can be retrieved at query time.
  module HypToBibId
    # Reads the hyp-to-bib-ID mapping from a JSON file on disk.
    # @param filename [String, Pathname] path to the +hyp_to_bibid.json+ file
    # @return [Hash{String => String}] mapping of HYP IDs to bib IDs
    # @raise [Errno::ENOENT] if the file does not exist
    def self.load_from_file!(filename)
      target = Pathname(filename)
      raise Errno::ENOENT.new("Can't find #{target}") unless target.exist?
      JSON.parse(File.read(target))
    end

    # Reads the mapping JSON from disk and adds it to Solr as a single document
    # with id +"hyp_to_bibid"+, then performs a hard commit.
    #
    # @param collection [SolrCloud::Collection] the target Solr collection
    # @param filename [String, Pathname] path to the +hyp_to_bibid.json+ file
    # @return [void]
    def self.dump_file_to_solr(collection:, filename:)
      data = File.read(filename)
      doc = {id: "hyp_to_bibid", hyp_to_bibid: data}
      collection.add(doc)
      collection.commit(hard: true)
    end

    # Retrieves the hyp-to-bib-ID mapping from a Solr collection.
    # @param collection [SolrCloud::Collection] the source Solr collection
    # @return [Hash{String => String}] the mapping of HYP IDs to bib IDs
    def self.get_from_solr(collection:)
      hyp_handler = "solr/#{collection.name}/hyp_to_bibid"
      resp = collection.get(hyp_handler)
      doc = resp.body["response"]["docs"].first
      JSON.parse(doc["hyp_to_bibid"])
    end
  end
end
