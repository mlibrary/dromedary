require "dromedary/services"

class AdminController < ApplicationController

  layout "uploader"

  def collections
    @collections ||= MedSolrCollections.new
  end

  State = Struct.new(:connection, :preview, :production, :same, :collections)

  # def current_state
  #
  #   connection = Dromedary::Services[:solr_connection]
  #   preview_alias_name = Dromedary::Services[:preview_alias]
  #   preview = connection.get_collection preview_alias_name
  #   production_alias_name = Dromedary::Services[:production_alias]
  #   production = connection.get_collection production_alias_name
  #   same = (preview and production and (preview.collection.name == production.collection.name))
  #   collections = connection.only_collections.map { |c| MedSolrCollection.new(c) }
  #                           .select { |c| c.is_med_collection? }
  #                           .sort { |a, b| b.date <=> a.date }
  #   num_of_aliased_collections = collections.count { |c| c.aliased? }
  #   first_collection_is_empty = (collections.first and collections.first.count == 0)
  #
  #   # Keep all the aliased ones, plus one more, plus _another_ one if the first collection is empty
  #   keep = num_of_aliased_collections + 1
  #   keep += 1 if first_collection_is_empty
  #
  #   collections[keep..-1] && collections[keep..-1].each { |c| c.deletable = true }
  #
  #   State.new(connection, preview, production, same, collections)
  # end

  def home
    render "admin/home", locals: { collections: collections }
  end

  def delete
    collection_name = params[:collection]
    coll = collections[collection_name]
    raise "Can't delete collection '#{collection_name}'; not found'" if coll.nil?
    raise "Collection '#{collection_name}' not eligible for deletion" if coll.do_not_delete
    cset = coll.configset
    coll.delete!
    cset.delete!
    render js: "window.location = '#{admin_path}';"
  end

  def check_errors
    preview_alias_name = Dromedary::Services[:preview_alias]
    production_alias_name = Dromedary::Services[:production_alias]

    errors = []
    if collections.preview.nil?
      errors << <<~NOALIAS
        The solr collection preview alias #{preview_alias_name} doesn't exist. Maybe indexing
        was never actually run?
      NOALIAS
    end
    if collections.released?
      errors << <<~SAME
        SAME DATA. Preview (#{preview_alias_name}) and production (#{production_alias_name}) already both point
        to the same underlying data, collection #{collections.preview.name}.
        Exited without doing anything.
      SAME
    end
    errors
  end

  def release
    errors = check_errors
    if errors.empty?
      enact_release(collection: collections.preview)
      render js: "window.location = '#{admin_path}';"
    else
      Rails.logger.warn errors
      render "admin/home", locals: { collections: collections, errors: errors }
    end
  end

  # When we force a release, also force med-preview to the same collections
  def force_release
    collection_name = params[:collection]
    target = collections[collection_name]
    errors = []
    if target.nil?
      errors << "Collection #{collection_name} doesn't exist. Aborting"
    end
    if errors.empty?
      collections.preview && collections.preview.aliases.each{|a| a.delete!}
      target.alias_as(Dromedary::Services[:preview_alias])
      enact_release(collection: target)
      render js: "window.location = '#{admin_path}';"
    else
      Rails.logger.warn errors
      render "admin/home", locals: { collections: collections, errors: errors }
    end
  end

  def enact_release(collection:)
    if collections.production
      collections.production.get_alias(Dromedary::Services[:production_alias]).delete!
    end
    collection.alias_as(Dromedary::Services[:production_alias])
  end
end
