class CaseState < State

  has_many :cases, :foreign_key => :state_id # Без этого ищется ключ case_state_id

  #-----------------------------------------------------------------------------
  def can_be_edited user=$current_user
    account_id == user.account_id and user.is_admin?
  end

  #-----------------------------------------------------------------------------
  def can_be_deleted user=$current_user
    account_id == user.account_id and user.is_admin? and cases.count == 0
  end
end
