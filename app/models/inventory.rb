class Inventory < ActiveRecord::Base
  account_and_user_protected
  has_many_attachmends
  
  belongs_to :owner, :polymorphic => true

  validates_presence_of :name
end