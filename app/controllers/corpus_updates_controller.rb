class CorpusUpdatesController < ApplicationController
  before_action :set_corpus
  before_action :set_corpus_update, only: [:show]

  def index
    @updates = CorpusUpdate.all
  end

  def new
    @corpus_update = CorpusUpdate.new
  end

  def create
    CorpusUpdate.create!(corpus_update_params)
    redirect_to corpus_updates_path
  end

  def show
    
  end

  private

  def corpus_update_params
    params.require(:corpus_update).permit(:corpus)
  end

  def set_corpus
    @corpus ||= Corpus.new
  end

  def set_corpus_update
    @update = CorpusUpdate.find(params[:id])
  end
end
