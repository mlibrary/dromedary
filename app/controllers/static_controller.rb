class StaticController < ApplicationController


  def temporarily_down
    @current_action = 'temporarily_down'
    render 'static/temporarily_down', layout: 'static'
  end
  

  def about_med
  	@current_action = 'about'
  	render 'static/about_med', :layout => 'static'
  end

 end
