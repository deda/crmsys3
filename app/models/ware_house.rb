class WareHouse < ActiveRecord::Base
  is_paranoid
  account_and_user_protected

  has_many :ware_items, :dependent => :destroy, :include => :ware
  has_many :wares, :through => :ware_items
  has_many :users
  has_many :sales
  has_many :ware_movements_from, :as => :from, :class_name => 'WareMovement'
  has_many :ware_movements_to, :as => :to, :class_name => 'WareMovement'
  
  validates_presence_of :name
  accepts_nested_attributes_for :ware_items,
    :allow_destroy => true,
    :reject_if => proc{|attributes| attributes['quantity'] == 0 || attributes['quantity'].blank?}
end
