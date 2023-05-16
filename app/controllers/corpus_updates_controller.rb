class CorpusUpdatesController < ApplicationController
  def index
    @updates = CorpusUpdate.all
  end

  def new
    @corpus_update = CorpusUpdate.new
  end

  def create
    CorpusUpdate.create!(corpus_update_params)
    redirect to corpus_updates_path
  end

  private

  def corpus_update_params
    params.require(:corpus_update).permit(:zip_file)
  end
end
