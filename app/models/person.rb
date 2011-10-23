class Person < Contact

  belongs_to  :company

  validates_presence_of :given_name
  accepts_nested_attributes_for :id_cards,
    :allow_destroy => true

  #-----------------------------------------------------------------------------
  # возвращает true, если заполнено хотя бы одно из неосновных полей
  # обязательные поля:
  #   given_name
  # основные поля:
  #   family_name
  #   company
  #   title
  #   phones
  #   emails
  #   tags
  # неосновные поля:
  #   additional_name
  #   nick_name
  #   bday
  #   pref
  #   suff
  #   parent
  #   urls
  #   ims
  #   addresses
  #   id_cards
  #
  def additional_info?
    return true if not nick_name.blank? or not bday.blank? or parent
    [urls,ims,addresses,id_cards].each do |items|
      items.each{ |item| return true unless item.empty? }
    end
    return false
  end

  #-----------------------------------------------------------------------------
  def formated_name
    "#{family_name} #{given_name} #{additional_name}"
  end

end
