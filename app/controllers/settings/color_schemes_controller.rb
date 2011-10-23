class Settings::ColorSchemesController < ApplicationController

  #-----------------------------------------------------------------------------
  def index
  end

  #-----------------------------------------------------------------------------
  def update
    current_user.settings.scheme = params[:scheme][:id]
    current_user.settings.save
    redirect_to settings_color_schemes_path
  end

end

