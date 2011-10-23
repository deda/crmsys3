class UserGroup < ActiveRecord::Base
  is_paranoid
  account_protected

  has_and_belongs_to_many :users, :join_table => :group_memberships
  has_and_belongs_to_many :cases, :join_table => :group_memberships

  validates_presence_of :name
end
