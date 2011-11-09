class CrmLog < ActiveRecord::Base

  belongs_to :user
  belongs_to :account

  scope :for_user, lambda {
    {:conditions => {:user_id => $current_user.id, :account_id => $current_account.id}}
  }
  scope :for_account, lambda {
    {:conditions => {:account_id => $current_account.id}}
  }

  #-----------------------------------------------------------------------------
  scope :for_object, lambda {|object|
    {:conditions => {
      :object => object.class.name,
      :record_id => object.id}}
  }

  #-----------------------------------------------------------------------------
  # то же что и object, но с учетом аккаунта
  scope :for_abject, lambda {|object|
    {:conditions => {
      :object => object.class.name,
      :record_id => object.id,
      :account_id => object.account_id}}
  }

  #-----------------------------------------------------------------------------
  def self.find_field_updates field
    find(:all, :conditions => [
      'oper_type=? AND fields LIKE ?',
      CrmLogger::OperType::UPDATE,
      "%#{field}%"])
  end

  #-----------------------------------------------------------------------------
  def self.find_last_field_value field, value
    items = find(:all, :order => :dati, :conditions => [
      '(oper_type=? OR oper_type=?) AND fields LIKE ? AND `values` LIKE ?',
      CrmLogger::OperType::CREATE,
      CrmLogger::OperType::UPDATE,
      "%#{field}%",
      "%#{value}%"])
    return nil unless items.any?
    items.reverse.each do |item|
      return item if item.value(field) == value
    end
    return nil
  end

  #-----------------------------------------------------------------------------
  def self.find_creation
    find(:first, :conditions => {:oper_type => CrmLogger::OperType::CREATE})
  end

  #-----------------------------------------------------------------------------
  def value field
    @fs ||= fields.split(',')
    @vs ||= values.split(',')
    return nil if not @fs or not @vs
    return nil if not (i = @fs.index(field))
    return @vs[i]
  end

end