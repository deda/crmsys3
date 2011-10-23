class Type < ActiveRecord::Base
  is_paranoid
  account_and_user_protected

  attr_protected :type

  has_many :contact_items

  validates_presence_of :name

  #-----------------------------------------------------------------------------
  # ищет/создает тип по имени и возвращает его
  def self.find_or_create conditions
    type = for_account.find(:first, :conditions => conditions)
    type = for_user.create(conditions) unless type
    return type
  end

  #-----------------------------------------------------------------------------
  # передается строка label и массив строк вида: ['work','cell','pref']
  # некоторые строки из массива переводятся и собираются в одну строку.
  # получается название_типа.
  # если массив пуст или название_типа пусто, то название_типа = label
  # затем по полученному названию ищется или строится тип
  def self.find_or_create_trans label, arr
    name = ''
    if arr and arr.any?
      type_for_translate = ['car','cell','fax','home','pager','pref','work']
      arr.each { |i| name += I18n.t(:"type_for_translate_#{i}") + ' ' if type_for_translate.include?(i.to_s) }
      name = name[0..-2]
    end
    if name.blank?
      name = label
    end
    return name.blank? ? nil : find_or_create(:name => name)
  end

  #-----------------------------------------------------------------------------
  def xablabel item_num
    return '' if name.blank?
    "item#{item_num}.X-ABLabel:#{Vcf::esc(name)}\n"
  end

end
