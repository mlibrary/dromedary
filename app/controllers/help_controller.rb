class HelpController < ApplicationController

  def help_root
    render "static/help", layout: 'static'
  end

  def help_page
    pg = params[:page]
    render "static/help/#{pg}", layout: 'static'
  end

end
