class Comment < ActiveRecord::Base
  is_paranoid
  account_and_user_protected
  has_many_attachmends

  belongs_to :owner, :polymorphic => true

  validates_presence_of :text
  validates_length_of :text, :maximum => 8192

  before_create :dont_save_if_present

  #-----------------------------------------------------------------------------
  def empty?
    text.blank?
  end

  #-----------------------------------------------------------------------------
  def self.string_for item
    c = item.comments.count
    c > 0 ? "<div class='comments_string'><b>#{I18n.t(:comments)}:</b>#{c}</div>" : ''
  end

  #-----------------------------------------------------------------------------
  def to_xml ops={}
    return '' if text.blank?
    level = ops[:level] || 0
    ws0 = '  ' * level
    s = "#{ws0}<comment>#{text}</comment>\n"
    return s
  end

  #-----------------------------------------------------------------------------
  def self.from_xml xml
    for_user.new(:text => xml)
  end

  #-----------------------------------------------------------------------------
  def to_vcf _nil
    "NOTE:#{Vcf::esc(text)}\n"
  end

  #-----------------------------------------------------------------------------
  def fields_for_crc
    [:text]
  end


private

  #-----------------------------------------------------------------------------
  def dont_save_if_present
    owner.comments.find(:first, :conditions => {:crc => new_crc}).nil?
  end

end
