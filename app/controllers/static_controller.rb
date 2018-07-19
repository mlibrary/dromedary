class StaticController < ApplicationController


  def about_med
  	@current_action = 'about'
  	render 'static/about_med', :layout => 'static'
  end

 end
