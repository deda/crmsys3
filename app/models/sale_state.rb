class SaleState < State

  has_many :sales, :foreign_key => :state_id

  validates_numericality_of :value,
    :greater_than_or_equal_to => 0,
    :less_than_or_equal_to => 100

  #-----------------------------------------------------------------------------
  def can_be_edited user=$current_user
    account_id == user.account_id and user.is_admin?
  end

  #-----------------------------------------------------------------------------
  def can_be_deleted user=$current_user
    account_id == user.account_id and user.is_admin? and sales.count == 0
  end
end
