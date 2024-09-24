S = Dromedary::Services

# Set up some places to work
S.register(:hyp_to_bibid) { Concurrent::Atom.new(:no_hyp_to_bib_id_yet) }
S.register(:collection_creation_date) { Concurrent::Atom.new(:no_creation_date_yet) }
S.register(:underlying_collection_name) {Concurrent::Atom.new(:no_underlying_name_yet) }


# Update the underlying concurrent variables.
# If the collection name underlying the (presumed) alias we're working with changes,
# update the collection-specific data and reset our understanding of the
# current collection name.
def update_timeout_variables
  Rails.logger.warn "################# CHECK FOR UPDATE ########################"
  collection = S[:solr_current_collection]
  # Bail if there's no current collection
  return unless collection
  actual_current_underlying_collection_name = collection.collection.name
  expected_underlying_collection_name = S[:underlying_collection_name].value
  if actual_current_underlying_collection_name != expected_underlying_collection_name
    Rails.logger.warn "################# PERFORMING UPDATE ########################"
    S[:hyp_to_bibid].reset MedInstaller::HypToBibId.get_from_solr(collection: collection)
    S[:collection_creation_date].reset Dromedary.compute_collection_creation_date(actual_current_underlying_collection_name)
    S[:underlying_collection_name].reset actual_current_underlying_collection_name
  end
end

# The timer, with `run_now`, is supposed to run immediately, but I keep getting not-set-yet
# errors, so we'll run it once manually on startup.
update_timeout_variables

# Run the update method ever 20 seconds
collection_timer = Concurrent::TimerTask.new(execution_interval: 20, run_now: true) do
  update_timeout_variables
end
# Need to call #execute to actually fire up the timer
collection_timer.execute
