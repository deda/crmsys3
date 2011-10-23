class WareItem < ActiveRecord::Base
  is_paranoid

  belongs_to :ware
  belongs_to :ware_house
  has_many :sale_items

  validates_existence_of :ware
  validates_existence_of :ware_house

end
