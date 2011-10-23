class WareMovement < ActiveRecord::Base
  is_paranoid

  belongs_to :user
  belongs_to :ware
  belongs_to :from, :class_name => 'WareHouse'
  belongs_to :to, :class_name => 'WareHouse'
  belongs_to :sale_item
  has_many :tasks, :as => :owner, :dependent => :destroy

  def self.state_value
    {
      :new                => 0,
      :canceled           => 98,
      :finished           => 99
    }
  end
end
