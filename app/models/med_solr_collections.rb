require "dromedary/services"
require_relative "med_solr_collection"

class MedSolrCollections

  include Enumerable
  NAME_MATCHER = Regexp.new  "\\A#{Dromedary::Services[:solr_collection_base]}_\\d{12}\\Z"

  # @return [Array<MEDSolrCollection>]
  attr_reader :collections

  def initialize
    @collections = Dromedary::Services[:solr_connection]
      .collections
      .select{|c| NAME_MATCHER.match?(c.name) }
      .map{|c| MedSolrCollection.new(c)}
      .sort{|a,b| b.creation_time <=> a.creation_time}
    set_keepers!
  end

  # @yield [MEDSolrCollection]
  def each(&blk)
    return enum_for(:each) unless block_given?
    @collections.each(&blk)
  end

  # @return [MEDSolrCollection]
  def [](key)
    @collections.find{|x| x.name == key}
  end

  # @return [MEDSolrCollection]
  def preview
    self.find{|c| c.preview?}
  end

  # @return [MEDSolrCollection]
  def production
    self.find{|c| c.production?}
  end

  def released?
    preview == production
  end

  def nothing_there?
    preview.nil? and production.nil?
  end

  def current_runner
    self.select{|c| c.might_still_be_running?}.first
  end


  # We can "force release" anything that isn't one of the following:
  #   * production (it's already released)
  #   * preview (it would have a release option already)
  #   * count == 0 (no data to release)
  def force_release_candidates
    self.reject{|c| c.aliased? or c.count == 0}
  end

  # A "keeper" is is preview, production, anything that might still be running,
  # and one more that has data in it
  def set_keepers!
    # Start by allowing for all to be deleted
    self.each {|c| c.allow_deletion!}

    preview and preview.forbid_deletion!
    production and production.forbid_deletion!
    current_runner and current_runner.forbid_deletion!

    most_recent_non_failure = self.select{|x| !x.do_not_delete }.reject(&:failure?).first
    most_recent_non_failure && most_recent_non_failure.forbid_deletion!
  end
end