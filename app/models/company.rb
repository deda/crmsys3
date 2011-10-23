class Company < Contact

  belongs_to :bank
  belongs_to :discount

  has_many :people, :dependent => :nullify
  has_many :sub_companies,
    :class_name  => 'Company',
    :foreign_key => :parent_id,
    :dependent   => :nullify

  validates_presence_of :given_name
  validates_uniqueness_of :given_name, :scope => [:account_id, :deleted_at]

  before_save :calc_discount, :set_family_name

  #-----------------------------------------------------------------------------
  # возвращает true, если заполнено хотя бы одно из неосновных полей
  # обязательные поля:
  #   given_name
  # основные поля:
  #   urls
  #   phones
  #   emails
  #   tags
  # неосновные поля:
  #   family_name
  #   bank
  #   rs
  #   inn
  #   kpp
  #   ogrn
  #   parent
  #   discount
  #   discount_value
  #   addresses
  #
  def additional_info?
    return true if (not family_name.blank? and (family_name != given_name)) or
      not rs.blank? or not inn.blank? or not kpp.blank? or not ogrn.blank? or
      parent_id or bank_id or discount_id or discount_value != 0
    [urls,addresses].each do |items|
      items.each{ |item| return true unless item.empty? }
    end
    return false
  end

  #-----------------------------------------------------------------------------
  def formated_name
    given_name
  end


private

  #-----------------------------------------------------------------------------
  def calc_discount
    self.discount_id, self.discount_value, price_discount = Discount.calc(
      discount_id,
      discount_value,
      0)
  end

end
