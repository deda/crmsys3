class IdCard < ActiveRecord::Base
  is_paranoid

  belongs_to :contact
  before_create :dont_save_if_present
  before_update :destroy_empty
  before_save :set_account_and_user

  #-----------------------------------------------------------------------------
  def empty?
    self.series.blank? and
    self.number.blank? and
    self.code.blank?   and
    self.whom.blank?   and
    self.when.blank?   and
    self.expiry.blank?
  end

  #-----------------------------------------------------------------------------
  def to_xml ops={}
    level = ops[:level] || 0
    ws0 = '  ' * level
    ws1 = '  ' * (level + 1)
    s = "#{ws0}<id_card>\n"
    s += "#{ws1}<ty>#{IdCardType.collection[self.ctype]}</ty>\n"
    s += "#{ws1}<se>#{self.series}</se>\n" unless self.series.blank?
    s += "#{ws1}<nu>#{self.number}</nu>\n" unless self.number.blank?
    s += "#{ws1}<co>#{self.code}</co>\n" unless self.code.blank?
    s += "#{ws1}<wo>#{self.whom}</wo>\n" unless self.whom.blank?
    s += "#{ws1}<we>#{self.when}</we>\n" unless self.when.blank?
    s += "#{ws1}<ex>#{self.expiry}</ex>\n" unless self.expiry.blank?
    s += "#{ws0}</id_card>\n"
    return s
  end

  def self.from_xml xml
    new(
      :ctype  => IdCardType.find_by_value(xml['ty']),
      :series => xml['se'],
      :number => xml['nu'],
      :code   => xml['co'],
      :whom   => xml['wo'],
      :when   => xml['we'],
      :expiry => xml['ex'])
  end

  #-----------------------------------------------------------------------------
  def to_s
    s = ''
    s += "<span class='type_name'>#{IdCardType.collection[self.ctype]}.</span> "
    s += "#{self.series}, " unless self.series.blank?
    s += "№ #{self.number}, " unless self.number.blank?
    s += "#{I18n::t(:code)}:#{self.code}, " unless self.code.blank?
    s += "#{I18n::t(:issued)}:" if not self.whom.blank? or not self.when.blank?
    s += "#{self.whom}, " unless self.whom.blank?
    s += "#{self.when}, " unless self.when.blank?
    s += "#{I18n::t(:expiry)}:#{self.expiry}, " unless self.expiry.blank?
    s[0..-3]
  end

  #-----------------------------------------------------------------------------
  def fields_for_crc
    [:ctype]
  end


private

  #-----------------------------------------------------------------------------
  def set_account_and_user
    self.account_id = contact.account_id
    self.user_id = contact.user_id
  end

  #-----------------------------------------------------------------------------
  def destroy_empty
    destroy if empty?
  end

  #-----------------------------------------------------------------------------
  def dont_save_if_present
    contact.id_cards.find(:first, :conditions => {:crc => new_crc}).nil?
  end

end

module IdCardType
  PASSPORT        = 0
  DRIVING_LICENSE = 1
  IDENTITY_CARD   = 2
  TRAVEL_PASSPORT = 3
  def self.collection
    [
      I18n.t(:id_card_passport),
      I18n.t(:id_card_driving_license),
      I18n.t(:id_card_identity_card),
      I18n.t(:id_card_travel_passport)
    ]
  end
  def self.find_by_value val
    return collection.index(val) || 0
  end
end