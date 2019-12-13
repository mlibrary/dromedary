class AdminController < ApplicationController
  extend MedInstaller::Logger

  def reload_hyp_to_bibid
    logger.info "Reloading hyp_to_bibid"
    Dromedary.load_fresh_hyp_to_bibid
    flash[:notice] = "Reloaded hyp_to_bibid"
    redirect_to root_path
  end

end
