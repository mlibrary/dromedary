class CorpusUpdate < ApplicationRecord
  include CorpusUploader::Attachment(:corpus)

  after_initialize :set_defaults

  class Status
    New = 'new'.freeze
    Preparing = 'preparing'.freeze
    Indexing = 'indexing'.freeze
    Complete = 'complete'.freeze
    Failed = 'failed'.freeze
  end

  def preparing
    self.status = Status::Preparing
  end

  def indexing
    self.status = Status::Indexing
  end

  def complete
    self.status = Status::Complete
  end

  def failed(cause = "Unknown error")
    self.status = Status::Failed
  end

  def preparing!
    preparing
    save
  end

  def indexing!
    indexing
    save
  end

  def complete!
    complete
    save
  end

  def failed!(cause = "Unknown error")
    failed(cause)
    save
  end

  private

  def set_defaults
    self.status ||= Status::New
  end
end
