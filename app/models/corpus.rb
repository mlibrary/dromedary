class Corpus
  UPDATE_ID = "corpus.update.id"
  
  def updating?
    active_update != nil
  end
  
  def active_update
    redis.get(UPDATE_ID)
  end
  
  def active_update=(id)
    redis.set(UPDATE_ID, id)
  end
  
  def clear_active_update
    redis.del(UPDATE_ID)
  end
  
  private
  def redis
    @@redis ||= Redis.new
  end
end