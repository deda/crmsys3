class Settings::TariffPlans::AccountTariffPlansController < Settings::TariffPlansController

  before_filter :find_tariff_plan, :only => [:edit, :update, :destroy]
  before_filter :find_tariff_plans, :only => [:mass_destroy]

  #-----------------------------------------------------------------------------
  def new
    @tariff_plan = AccountTariffPlan.for_user.new
    super
  end

  #-----------------------------------------------------------------------------
  def create
    @tariff_plan = AccountTariffPlan.for_user.new(params[:tariff_plan])
    super
  end


private

  #-----------------------------------------------------------------------------
  def find_tariff_plan
    @tariff_plan = AccountTariffPlan.find(params[:id])
  end

  #-----------------------------------------------------------------------------
  def before_render
    @tariff_plans = AccountTariffPlan.find(:all)
  end

  #-----------------------------------------------------------------------------
  def find_tariff_plans
    @tariff_plans = AccountTariffPlan.find(params[:ids])
  end

end

