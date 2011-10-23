class Settings::AccountController < ApplicationController

  before_filter :admin_only

  #-----------------------------------------------------------------------------
  def index
    before_render
  end

  #-----------------------------------------------------------------------------
  def update
    @account = Account.find(params[:id])
    if current_user.account == @account
      @account.name = params[:account][:name]
      @account.save
      @account.settings.locale = params[:account][:settings][:locale]
      @account.settings.save
    else
      @account = current_user.account
    end
    responds_to_parent do
      render :action => :update
    end
  end


private

  #-----------------------------------------------------------------------------
  def before_render
    @account = current_user.account
  end

end

