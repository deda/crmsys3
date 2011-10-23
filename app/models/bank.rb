class Bank < Contact

  has_many :companies, :dependent => :nullify

  validates_presence_of :given_name
  validates_uniqueness_of :given_name, :scope => [:account_id, :deleted_at]

  before_save :set_family_name

  #-----------------------------------------------------------------------------
  # возвращает true, если заполнено хотя бы одно из неосновных полей
  # обязательные поля:
  #   given_name
  # основные поля:
  #   urls
  #   phones
  #   emails
  #   group
  # неосновные поля:
  #   family_name
  #   bic
  #   cs
  #   inn
  #   kpp
  #   ogrn
  #   addresses
  #
  def additional_info?
    (!family_name.blank? && (family_name != given_name)) ||
    !bic.blank? ||
    !cs.blank? ||
    !inn.blank? ||
    !kpp.blank? ||
    !ogrn.blank? ||
    addresses.any?
  end

  #-----------------------------------------------------------------------------
  def formated_name
    given_name
  end

end
