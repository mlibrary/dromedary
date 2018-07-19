class StaticController < ApplicationController

  def help_med
  	@current_action = 'help'
  	render :layout => 'static'
  end

  def help
    @current_action = "help"
    render "static/help/dictionary", layout: 'static'
  end

  def about_med
  	@current_action = 'about'
  	render :layout => 'static'
  end

 end
