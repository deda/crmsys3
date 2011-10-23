class Commodity < ActiveRecord::Base
  is_paranoid :order => :name
  account_and_user_protected

  validates_presence_of :name, :art, :price_out, :country
  validates_uniqueness_of :art

  #-----------------------------------------------------------------------------
  def convert
    [name, id]
  end

end
