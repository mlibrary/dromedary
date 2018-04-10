class StaticController < ApplicationController

  def help_med
  	@current_action = 'help'
  	render :layout => 'static'
  end

  def about_med
  	@current_action = 'about'
  	render :layout => 'static'
  end

 end
