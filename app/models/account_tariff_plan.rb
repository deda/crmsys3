class AccountTariffPlan < ActiveRecord::Base
  is_paranoid
  user_protected

  has_many :accounts, :foreign_key => :tariff_plan_id

  validates_presence_of :name, :max_users, :max_mbytes, :max_contacts
  validates_numericality_of :max_users, :max_mbytes, :max_contacts, :price

  #-----------------------------------------------------------------------------
  def can_be_edited user=$current_user
    user.is_accounts_admin?
  end

  #-----------------------------------------------------------------------------
  def can_be_deleted user=$current_user
    user.is_accounts_admin? and accounts.count == 0
  end

  def formatted_name
    s = ''
    s += ", #{yield(:with_commodities)}" if with_commodities
    s += ", #{yield(:with_cases)}" if with_cases
    s += ", #{yield(:with_projects)}" if with_projects
    "#{name} (#{yield(:users)}:#{max_users}, Mb:#{max_mbytes}, #{yield(:contacts)}:#{max_contacts}#{s})"
  end

end