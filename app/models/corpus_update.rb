class CorpusUpdate < ApplicationRecord
  include CorpusUploader::Attachment(:corpus)
end
