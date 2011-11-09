class Account < ActiveRecord::Base
  include Settings
  is_paranoid

  has_many :users,          :dependent => :destroy
  has_many :admins,         :dependent => :destroy, :class_name => 'User', :conditions => {:is_admin => true}
  has_many :commodities,    :dependent => :destroy
  has_many :ware_houses,    :dependent => :destroy
  has_many :tasks,          :dependent => :destroy
  has_many :comments,       :dependent => :destroy
  has_many :projects,       :dependent => :destroy
  has_many :discounts,      :dependent => :destroy
  has_many :measures,       :dependent => :destroy
  has_many :categories,     :dependent => :destroy
  has_many :sales,          :dependent => :destroy
  has_many :services,       :dependent => :destroy, :class_name => 'Service'
  has_many :wares,          :dependent => :destroy, :class_name => 'Ware'
  has_many :user_groups,    :dependent => :destroy
  has_many :attachmends,    :dependent => :destroy
  # контакты -------------------------------------------------------------------
  has_many :contacts,       :dependent => :destroy
  has_many :people,         :dependent => :destroy
  has_many :companies,      :dependent => :destroy
  has_many :banks,          :dependent => :destroy
  # типы -----------------------------------------------------------------------
  has_many :types,          :dependent => :destroy
  has_many :address_types,  :dependent => :destroy
  has_many :email_types,    :dependent => :destroy
  has_many :im_protocols,   :dependent => :destroy
  has_many :im_types,       :dependent => :destroy
  has_many :phone_types,    :dependent => :destroy
  has_many :url_types,      :dependent => :destroy

  belongs_to :tariff_plan, :class_name => 'AccountTariffPlan'

  accepts_nested_attributes_for :admins

  validate :end_time, :presense => true
  validate :name, :presense => true

  def convert
    [name.to_s, id]
  end

  #-----------------------------------------------------------------------------
  def statistic
    active_records = 0
    deteled_records = 0
    Account.reflections.
      select{|r| r[1].macro == :has_many or r[1].macro == :has_one}.
      map{|r| r[0]}.
      select{|r|
        begin
          o = Object.const_get(r.to_s.singularize.camelize)
          o.is_a?(Class) and o.superclass == ActiveRecord::Base
        rescue
          false
        end
      }.
      each do |r|
        active_records += send(r).count
        deteled_records += send(r).count_destroyed_only(:conditions => {:account_id => id})
      end
    return {
      :active_records => active_records,
      :deleted_records => deteled_records}
  end

  #-----------------------------------------------------------------------------
  def can_be_edited user=$current_user
    user.is_admin? and user.account.is_director? and not self.is_director?
  end
  def can_be_deleted user=$current_user
    user.is_admin? and user.account.is_director? and not self.is_director?
  end

  def self.director
    find(:first, :conditions => {:is_director => true})
  end

end
