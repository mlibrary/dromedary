class UpdateService
  UPDATE_ID_KEY = 'mec.update_id'

  class AlreadyUpdatingError < StandardError; end

  def initialize(
    redis: Redis.new,
    prepare_command: MedInstaller::PrepareNewData.new(command_name: 'newdata prepare'),
    index_command: MedInstaller::IndexNewData.new(command_name: 'newdata index')
  )
    @redis = redis
    @prepare_command = prepare_command
    @index_command = index_command
  end

  def active?
    !!active_update_id
  end

  def process(corpus_update)
    enforce_inactive!
    lock_update(corpus_update.id)

    corpus_update.preparing!
    prepare(corpus_update)

    corpus_update.indexing!
    index

    corpus_update.complete!
    unlock_update
  end

  private

  def enforce_inactive!
    id = active_update_id
    if id
      raise AlreadyUpdatingError, "Already processing id: #{id}"
    end
  end

  def active_update_id
    redis.get(UPDATE_ID_KEY)
  end

  def lock_update(id)
    redis.set(UPDATE_ID_KEY, id)
  end

  def unlock_update
    redis.del(UPDATE_ID_KEY)
  end

  def prepare(corpus_update)
    corpus_update.corpus.download do |zipfile|
      prepare_command.call(zipfile: zipfile.path)
    end
  end

  def index
    index_command.call(force: true)
  end

  attr_reader :redis, :prepare_command, :index_command
end
