class CorpusUpdateJob
  include Sidekiq::Job

  def perform(update_id)
    update = CorpusUpdate.find(update_id)
    service = UpdateService.new
    service.process(update)
  end
end
