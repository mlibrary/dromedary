require "dromedary/services"

class MedSolrCollection < SimpleDelegator

  EXPECTED_INDEXING_TIME_IN_MINUTES = 75
  TOO_DARN_LONG_IN_MINUTES = 80

  attr_accessor :do_not_delete

  def initialize(collection)
    @collection = collection
    super(@collection)
  end

  def preview?
    has_alias? Dromedary::Services[:preview_alias]
  end

  def production?
    has_alias? Dromedary::Services[:production_alias]
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

  def creation_time
    Dromedary.compute_collection_creation_date(name)
  end

  def age_in_minutes
    ((Time.current - creation_time) / 60).to_i
  end

  def might_still_be_running?
    ! (count > 0 or failure?)
  end

  def expected_completion_time
    creation_time + EXPECTED_INDEXING_TIME_IN_MINUTES * 60
  end

  def expected_completion_in_minutes
    EXPECTED_INDEXING_TIME_IN_MINUTES - age_in_minutes
  end

  def failure?
    count == 0 and age_in_minutes > TOO_DARN_LONG_IN_MINUTES
  end

  def allow_deletion!
    @do_not_delete = false
  end

  def forbid_deletion!
    @do_not_delete = true
  end

end
