class AccountTariffPlan < ActiveRecord::Base
  is_paranoid

  has_many :accounts, :foreign_key => :tariff_plan_id
  belongs_to :user
  attr_protected :user_id

  validates :name, :presence => true
  validates :max_users, :presence => true
  validates :max_mbytes, :presence => true
  validates :max_contacts, :presence => true
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