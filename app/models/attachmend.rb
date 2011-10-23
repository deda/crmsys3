class Attachmend < ActiveRecord::Base
  is_paranoid
  account_and_user_protected

  belongs_to :owner, :polymorphic => true
  has_attached_file :object
  before_create :check_overflow

  #-----------------------------------------------------------------------------
  # Присоединяет owner`у все его неприсоединенные вложения
  def self.attache_attachmends_for owner
    find(:all, :conditions => {
      :account_id => owner.account_id,
      :user_id    => owner.user_id,
      :owner_type => owner.class.base_class.name.camelize,
      :owner_id   => nil}).each { |a|
    a.update_attribute(:owner_id, owner.id) }
  end

  #-----------------------------------------------------------------------------
  # Возвращает массив вложений для owner`а.
  # Также, включает неприсоединенные вложения, если owner есть new_record
  def self.attachmends_for owner
    if owner.new_record?
      for_user(owner.user).find(:all, :conditions => {:owner_type => owner.class.base_class.name.camelize, :owner_id => nil})
    else
      for_account(owner.account).find(:all, :conditions => {:owner_type => owner.class.base_class.name.camelize, :owner_id => owner.id})
    end    
  end


private

  #-----------------------------------------------------------------------------
  def check_overflow
    total_size = Attachmend.sum(:object_file_size, :conditions => {:account_id => account.id})
    if total_size >= account.tariff_plan.max_mbytes * 1024
      errors.add(:overflow, I18n::t(:account_full_mbytes))
      return false
    end
    return true
  end

end
