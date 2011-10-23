class Settings::CaseStatesController < ApplicationController

  before_filter :admin_only
  before_filter :find_state, :only => [:edit, :update, :destroy]

  #-----------------------------------------------------------------------------
  def index
    before_render
  end

  #-----------------------------------------------------------------------------
  def new
    @state = CaseState.for_user.new
  end

  #-----------------------------------------------------------------------------
  def create
    @state = CaseState.for_user.new(params[:case_state])
    respond_to_parent do
      if @state.save
        before_render
        render :action => :update
      else
        render :action => :new
      end
    end
  end

  #-----------------------------------------------------------------------------
  def edit
    before_render
    render :action => :new
  end

  #-----------------------------------------------------------------------------
  def update
    responds_to_parent do
      if @state.update_attributes(params[:case_state])
        before_render
        render :action => :update
      else
        render :action => :new
      end
    end
  end

  #-----------------------------------------------------------------------------
  def destroy
    @state.destroy if @state.can_be_deleted
    before_render
    render :action => :destroy
  end

  #-----------------------------------------------------------------------------
  def mass_destroy
    CaseState.for_account.find(params[:ids]).each { |state|
      state.destroy if state.can_be_deleted
    }
    before_render
    render :action => :destroy
  end


private

  #-----------------------------------------------------------------------------
  def find_state
    @state = CaseState.for_account.find(params[:id])
  end

  #-----------------------------------------------------------------------------
  def before_render
    @states = CaseState.for_account.find(:all)
  end

end

