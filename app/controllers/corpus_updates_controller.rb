class CorpusUpdatesController < ApplicationController
  before_action :set_corpus_update, only: [:show, :process_update]
  layout "static"

  def index
    @corpus_updates = CorpusUpdate.all.order(updated_at: :desc)
    render "corpus_updates/index", layout: "static"
  end

  def new
    @corpus_update = CorpusUpdate.new
  end

  def create
    CorpusUpdate.create!(corpus_update_params)
    redirect_to corpus_updates_path
  end

  def show
    @update_in_progress = update_service.active?
    @active_update_id = update_service.active_update_id
  end

  def process_update
    if update_service.active?
      @active_update_id = update_service.active_update_id
      render 'corpus_updates/already_active'
    else
      CorpusUpdateJob.perform_async(@corpus_update.id)
    end
  end

  private

  def corpus_update_params
    params.require(:corpus_update).permit(:corpus)
  end

  def set_corpus_update
    @corpus_update = CorpusUpdate.find(params[:id])
  end

  def update_service
    @update_service ||= UpdateService.new
  end
end
