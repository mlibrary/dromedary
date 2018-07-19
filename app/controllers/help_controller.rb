class HelpController < ApplicationController

  def root
    render "static/help", layout: 'static'
  end

  def page
    pg = params[:page]
    render "static/help/#{pg}", layout: 'static'
  end

end
