class User < ActiveRecord::Base
  include Clearance::User
  include Settings
  is_paranoid
  has_one_avatar

  belongs_to :account
  belongs_to :ware_house
  
  has_many :contacts,                 :dependent => :destroy
  has_many :ware_movements,           :dependent => :destroy

  has_many :posted_sales,             :class_name => 'Sale', :dependent => :destroy
  has_many :received_sales,           :class_name => 'Sale', :dependent => :destroy, :foreign_key => :recipient_id

  has_many :posted_tasks,             :class_name => 'Task', :dependent => :destroy
  has_many :posted_completed_tasks,   :class_name => 'Task', :dependent => :destroy, :conditions => {:completed => true}

  has_many :received_tasks,           :class_name => 'Task', :dependent => :destroy, :foreign_key => :recipient_id
  has_many :received_completed_tasks, :class_name => 'Task', :dependent => :destroy, :foreign_key => :recipient_id, :conditions => {:completed => true}

  has_many :posted_cases,             :class_name => 'Case', :dependent => :destroy
  has_many :received_cases,           :class_name => 'Case', :dependent => :destroy, :foreign_key => :recipient_id

  has_and_belongs_to_many :user_groups, :join_table => :group_memberships

  attr_accessible :name, :is_admin
  validates :name, :presence => true

  before_create :check_overflow

  #-----------------------------------------------------------------------------
  # нельзя использовать account_protected из-за Clearance
  # а также, чтобы можно было создавать аккаунт и его админа одновременно.
  # для этого нельзя определять validates_presence_of :account, т.к. админ
  # должен быть сохранени раньше аккаунта (которого еще нет)
  # использовать транзакции? - тоже нет. потому что не получится получать
  # сообщения об ошибках, т.к. транзацкии прерываются по исключениям.
  # записи данного аккаунта
  scope :for_account, lambda{ |account|
    account ||= $current_account
    {:conditions => account ? {:account_id => account.id} : ''}
  }

  #-----------------------------------------------------------------------------
  def convert
    [name, id]
  end

  #-----------------------------------------------------------------------------
  # возвращает true, если пользователь может создавать аккаунты и управлять ими
  def is_accounts_admin?
    is_admin? and account.is_director?
  end

  #-----------------------------------------------------------------------------
  def can_be_edited user=$current_user
    account_id == user.account_id and (user.is_admin? or user.id == id)
  end

  #-----------------------------------------------------------------------------
  def can_be_deleted user=$current_user
    account_id == user.account_id and user.is_admin? and user.id != id
  end

  #-----------------------------------------------------------------------------
  def name_w_email
    "#{name} <#{email}>"
  end


private

  #-----------------------------------------------------------------------------
  def check_overflow
    if account.users.size >= account.tariff_plan.max_users
      errors.add(:name, I18n::t(:account_full_users))
      return false
    end
    return true
  end
  
end
