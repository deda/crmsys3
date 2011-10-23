class UserMessage < ActiveRecord::Base
  is_paranoid
  account_and_user_protected
  has_many_attachmends

  belongs_to :recipient, :class_name => 'User'
  belongs_to :parent,
             :class_name   => 'Contact'
  has_many   :children,
             :class_name   => 'Contact',
             :foreign_key  => :parent_id,
             :dependent    => :destroy

  validates_presence_of :text
  validates_length_of :text, :maximum => 8192

end
