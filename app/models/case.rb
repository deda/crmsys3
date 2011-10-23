class Case < ActiveRecord::Base
  extend Paging
  is_paranoid :order => :name
  account_and_user_protected
  def_recently_scopes
  has_many_tags CaseTag
  process_visibility

  has_many :tasks,      :dependent => :destroy, :as => :owner, :order => :position
  has_many :comments,   :dependent => :destroy, :as => :owner
  has_many :inventory_items, :as => :owner, :dependent => :destroy, :order => :position

  belongs_to :sale
  belongs_to :state, :class_name => 'CaseState'
  belongs_to :recipient, :class_name => 'User'

  validates_presence_of :name, :state, :sale

  #-----------------------------------------------------------------------------
  def formated_name
    if code.blank?
      name
    else
      "#{code} - #{name}"
    end
  end

  #-----------------------------------------------------------------------------
  def can_be_edited user=$current_user
    account_id == user.account_id and (user.is_admin? or user.id == user_id or user.id == recipient_id)
  end

end