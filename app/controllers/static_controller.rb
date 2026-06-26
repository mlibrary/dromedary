class StaticController < ApplicationController
  def about_med
    render "static/about_med", layout: "static"
  end
end
