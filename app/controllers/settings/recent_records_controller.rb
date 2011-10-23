class Settings::RecentRecordsController < ApplicationController

  #-----------------------------------------------------------------------------
  def index
    @rd_contact = current_user.settings.recent_contact
    @rd_task = current_user.settings.recent_task
    @rd_sale = current_user.settings.recent_sale
    @rd_case = current_user.settings.recent_case
  end

  #-----------------------------------------------------------------------------
  def create
    @rd_contact = from_params(:contact)
    @rd_task = from_params(:task)
    @rd_sale = from_params(:sale)
    @rd_case = from_params(:case)
    responds_to_parent do
      unless @error
        current_user.settings.recent_contact = @rd_contact
        current_user.settings.recent_task = @rd_task
        current_user.settings.recent_sale = @rd_sale
        current_user.settings.recent_case = @rd_case
        current_user.settings.save
        render :action => :update
      else
        render :action => :create
      end
    end
  end


private

  def from_params item
    v = params[:recent_days][item]
    unless v.blank?
      begin
        v = v.to_i
      end
    end
    error_key = :"error_recent_days_#{item.to_s}"
    if not v or v <= 0
      flash[error_key] = 'Invalid value'
      @error = true
    else
      flash[error_key] = nil
    end
    return v
  end

end

