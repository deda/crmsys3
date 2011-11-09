class Sale < ActiveRecord::Base
  extend Paging
  is_paranoid
  account_and_user_protected
  has_many_attachmends
  has_many_tags SaleTag
  def_recently_scopes
  process_visibility

  belongs_to :contact
  belongs_to :ware_house
  belongs_to :recipient, :class_name => 'User'
  belongs_to :state, :class_name => 'SaleState'

  has_many :sale_items, :dependent => :destroy
  has_many :tasks,      :dependent => :destroy, :as => :owner, :order => :position
  has_many :comments,   :dependent => :destroy, :as => :owner
  has_many :cases,      :dependent => :destroy

  validates_presence_of :name, :contact, :recipient, :state

  accepts_nested_attributes_for :sale_items,
    :allow_destroy => true

  before_validation :set_prices
  before_save :calc_discount

  #-----------------------------------------------------------------------------
  scope :sales,     :conditions => {:is_sale => true}
  scope :purchases, :conditions => {:is_sale => false}

  #-----------------------------------------------------------------------------
  def ware_movements
    return [] if new_record?
    WareMovement.find_by_sql("
      SELECT *
      FROM ware_movements wm
      WHERE wm.deleted_at IS NULL AND wm.sale_item_id IN (
        SELECT si.id
        FROM sale_items si
        WHERE si.sale_id=#{self.id})")
  end

  #-----------------------------------------------------------------------------
  def formated_name
    name
  end

  #-----------------------------------------------------------------------------
  def can_be_edited user=$current_user
    account_id == user.account_id and (user.is_admin? or recipient_id == user.id)
  end
  def can_be_deleted user=$current_user
    account_id == user.account_id and (user.is_admin? or recipient_id == user.id)
  end


private

  #-----------------------------------------------------------------------------
  def calc_discount
    if account.tariff_plan.with_commodities
      self.discount_id, self.discount_value, self.price_total = Discount.calc(
        discount_id,
        discount_value,
        price_discount)
    end
  end

  #-----------------------------------------------------------------------------
  def set_prices
    self.price_in    = 0 unless self.price_in
    self.price_out   = 0 unless self.price_out
    self.price_total = 0 unless self.price_total
  end

end
