require "dromedary/services"

class AdminController < ApplicationController

  layout "uploader"


  class MedSolrCollection < SimpleDelegator

    NAME_MATCHER = Regexp.new  "\\A#{Dromedary::Services[:solr_collection_base]}_\\d{12}\\Z"


    attr_accessor :deletable
    def initialize(collection)
      @collection = collection
      super(@collection)
      @deletable = false
    end

    def is_med_collection?
      NAME_MATCHER.match?(name)
    end

    def alias_display
      if aliased?
        alias_names.join(", ")
      else
        "none"
      end
    end

    def date
      Dromedary.compute_collection_creation_date(name)
    end

  end

  State = Struct.new(:connection, :preview, :production, :same, :collections)

  def current_state
    connection = Dromedary::Services[:solr_connection]
    preview_alias_name = Dromedary::Services[:preview_alias]
    preview = connection.get_collection preview_alias_name
    production_alias_name = Dromedary::Services[:production_alias]
    production = connection.get_collection production_alias_name
    same = (preview and production and (preview.collection.name == production.collection.name))
    collections = connection.only_collections.map{|c| MedSolrCollection.new(c)}
                            .select{|c| c.is_med_collection?}
                            .sort{|a,b| b.date <=> a.date}
    num_of_aliased_collections = collections.count{|c| c.aliased? }
    first_collection_is_empty = (collections.first and collections.first.count == 0)

    # Keep all the aliased ones, plus one more, plus _another_ one if the first collection is empty
    keep = num_of_aliased_collections + 1
    keep += 1 if first_collection_is_empty

    collections[keep..-1] && collections[keep..-1].each {|c| c.deletable = true}

    State.new(connection, preview, production, same, collections)
  end

  def nothing_exists?(state = current_state)
    state.production.nil? and state.preview.nil?
  end




  def home
    render "admin/home", locals: { state: current_state}
  end

  def delete
    collection_name = params[:collection]
    collections = current_state.collections
    collection = MedSolrCollection.new(collections.select{|x| x.name == collection_name}).first
    if collection.deletable
      collection.delete!
    else
      raise "Collection '#{collection.name}' not deleteable.
      Deletable value is #{collection.deletable}. Deleteables are #{collections.select{|c| c.deletable}}"
    end
    render js: "window.location = '#{admin_path}';"
  end

  def check_errors(state = current_state)
    # Verify that we have everything
    connection = state.connection
    preview_alias_name = Dromedary::Services[:preview_alias]
    preview = state.preview
    production_alias_name = Dromedary::Services[:production_alias]
    production = state.production
    sample_collection_name = "#{Dromedary::Services[:solr_collection_base]}_202410101115"
    sample_collection_form = "#{Dromedary::Services[:solr_collection_base]}_YYYYMMDDHHmm"

    errors = []
    if preview.nil?
      errors << <<~NOALIAS
        The solr collection preview alias #{preview_alias_name} doesn't exist. Maybe indexing
        was never actually run?
      NOALIAS
    end

    if preview and not preview.alias?
      errors << <<~NOTALIAS
        The solr collection preview alias #{preview_alias_name} should just be an alias that points 
        at a real solr collection, with a timestamped name of the form #{sample_collection_name}. 
        #{preview_alias_name} is pointing at an actual collection, which should never happen. To fix
        this, rename the collection to a valid timestamped named (of the form #{sample_collection_form}),
        then create the alias "#{preview_alias_name}" to point at it.
      NOTALIAS
    end

    if production and (not production.alias?)
      errors << <<~PRODNOTALIAS
        The solr collection alias for production data, #{production_alias_name}, is not, in fact, an alias,
        but a "real" collection with real data in it. That should never happen, and is likely the result
        of someone trying to fix something else that went wrong. To fix this, you should rename the
        collection #{production_alias_name} to an appropriate timestamp-based name (something like 
        #{sample_collection_name}, of the form #{sample_collection_form}), and then create an alias named
        #{production_alias_name} that points to it. 
      PRODNOTALIAS
    end

    if state.production and state.preview and (Dromedary.underlying_real_collection_name(coll: preview) ==
      Dromedary.underlying_real_collection_name(coll: production))
      errors << <<~SAME
        SAME DATA. Preview (#{preview_alias_name}) and production (#{production_alias_name}) already both point
        to the same underlying data, collection #{Dromedary.underlying_real_collection_name(coll: preview)}.
        Exited without doing anything.
      SAME
    end

    errors
  end

  def release
    state = current_state
    errors = check_errors(state)
    if errors.size == 0
      real_collection_name = Dromedary.underlying_real_collection_name(coll: state.preview)
      if state.production
        state.production.switch_collection_to(real_collection_name)
      else
        state.preview.collection.alias_as(Dromedary::Services[:production_alias])
      end
      state = current_state
      render js: "window.location = '#{admin_path}';"
    else
      render "admin/home", locals: { state: state, errors: errors }
    end

  end
end
