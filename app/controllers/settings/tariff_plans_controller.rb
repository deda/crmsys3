class Settings::TariffPlansController < ApplicationController

  before_filter :accounts_admin_only

  #-----------------------------------------------------------------------------
  def new
    render :template => 'settings/tariff_plans/new'
  end

  #-----------------------------------------------------------------------------
  def index
    before_render
    render :template => 'settings/tariff_plans/index'
  end

  #-----------------------------------------------------------------------------
  def edit
    before_render
    render :template => 'settings/tariff_plans/new'
  end

  #-----------------------------------------------------------------------------
  def update
    responds_to_parent do
      if @tariff_plan.update_attributes(params[:tariff_plan])
        before_render
        render :template => 'settings/tariff_plans/update'
      else
        render :template => 'settings/tariff_plans/new'
      end
    end
  end

  #-----------------------------------------------------------------------------
  def create
    respond_to_parent do
      if @tariff_plan.save
        before_render
        render :template => 'settings/tariff_plans/update'
      else
        render :template => 'settings/tariff_plans/new'
      end
    end
  end

  #-----------------------------------------------------------------------------
  def destroy
    @tariff_plan.destroy if @tariff_plan.can_be_deleted
    before_render
    render :template => 'settings/tariff_plans/destroy'
  end

  #-----------------------------------------------------------------------------
  def mass_destroy
    @tariff_plans.each { |tp|
      tp.destroy if tp.can_be_deleted
    }
    before_render
    render :template => 'settings/tariff_plans/destroy'
  end

end
