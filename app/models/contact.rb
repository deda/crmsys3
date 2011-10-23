class Contact < ActiveRecord::Base
  include Vcf
  extend Paging
  is_paranoid
  account_and_user_protected
  has_many_attachmends
  has_many_tags ContactTag
  def_recently_scopes
  has_one_avatar

  attr_protected :type

  has_many    :sales,       :dependent => :destroy
  has_many    :phones,      :dependent => :destroy
  has_many    :emails,      :dependent => :destroy
  has_many    :urls,        :dependent => :destroy
  has_many    :ims,         :dependent => :destroy
  has_many    :id_cards,    :dependent => :destroy
  has_many    :comments,    :dependent => :destroy, :as => :owner
  has_many    :addresses,   :dependent => :destroy, :as => :owner
  has_many    :tasks,       :dependent => :destroy, :as => :owner
 
  has_and_belongs_to_many :cases

  # acts as tree
  belongs_to  :parent,
              :class_name   => 'Contact'
  has_many    :children,
              :class_name   => 'Contact',
              :foreign_key  => :parent_id,
              :dependent    => :nullify

  validates_associated :phones, :emails, :urls, :ims, :addresses

  before_validation :check_parent
  before_create :check_overflow

  #-----------------------------------------------------------------------------
  def empty?
    given_name.blank?
  end

  #-----------------------------------------------------------------------------
  accepts_nested_attributes_for :phones, :emails, :urls, :ims,
    :allow_destroy  => true,
    :reject_if      => proc{ |attributes| attributes['value'].blank? }
  accepts_nested_attributes_for :addresses,
    :allow_destroy  => true

  #-----------------------------------------------------------------------------
  def convert
    [formated_name, id]
  end

  #-----------------------------------------------------------------------------
  # ищет контакт по заданным условиям
  # если находит, возвращает его, если нет, создает новый и возвращает его
  def self.find_or_new conditions
    contact = for_account.find(:first, :conditions => conditions)
    contact = for_user.new(conditions) unless contact
    return contact
  end

  #-----------------------------------------------------------------------------
  # экспорт контакта в XML
  def to_xml ops={}
    level = ops[:level] || 0
    ws0 = '  ' * level
    ws1 = '  ' * (level + 1)
    ws2 = '  ' * (level + 2)
    s = "#{ws0}<contact>\n#{ws1}<ty>#{self.class.name.underscore[0,1]}</ty>\n#{ws1}<gn>#{given_name}</gn>\n"

    if is_a? Person
      s += "#{ws1}<fn>#{family_name}</fn>\n" unless family_name.blank?
      s += "#{ws1}<an>#{additional_name}</an>\n" unless additional_name.blank?
      s += "#{ws1}<hp>#{pref}</hp>\n" unless pref.blank?
      s += "#{ws1}<hs>#{suff}</hs>\n" unless suff.blank?
      s += "#{ws1}<bd>#{bday}</bd>\n" unless bday.blank?
      s += "#{ws1}<ti>#{title}</ti>\n" unless title.blank?
      s += "#{ws1}<nn>#{nick_name}</nn>\n" unless nick_name.blank?
      s += "#{ws1}<co>#{company.given_name}</co>\n" if company
      if parent
        s += "#{ws1}<pa>\n"
        s += "#{ws2}<gn>#{given_name}</gn>\n"
        s += "#{ws2}<fn>#{family_name}</fn>\n" unless family_name.blank?
        s += "#{ws2}<an>#{additional_name}</an>\n" unless additional_name.blank?
        s += "#{ws1}</pa>\n"
      end
    else
      s += "#{ws1}<rs>#{rs}</rs>\n" unless rs.blank?
      s += "#{ws1}<in>#{rs}</in>\n" unless inn.blank?
      s += "#{ws1}<kp>#{rs}</kp>\n" unless kpp.blank?
      s += "#{ws1}<og>#{rs}</og>\n" unless ogrn.blank?
      s += "#{ws1}<di>#{discount_value}</di>\n" unless discount_value == 0.0
      if parent
        s += "#{ws1}<pa>\n"
        s += "#{ws2}<gn>#{given_name}</gn>\n"
        s += "#{ws1}</pa>\n"
      end
    end

    [phones,emails,urls,ims,addresses,comments,tags,id_cards].each do |a|
      a.each { |i| s += i.to_xml(:level => level + 1) }
    end

    s += avatar.to_xml(:level => level + 1) if avatar

    s += "#{ws0}</contact>\n"
    return s
  end

  #-----------------------------------------------------------------------------
  # импорт контакта из XML
  def self.from_xml xml
    if xml['ty'] == 'c'
      # создаем компанию
      contact = Company.find_or_new({:given_name => xml['gn']||''})
    else
      # создаем персону
      contact = Person.find_or_new({:given_name => xml['gn']||'', :family_name => xml['fn']||'', :additional_name => xml['an']||''})
      contact.pref      = xml['hp']
      contact.suff      = xml['hs']
      contact.title     = xml['ti']
      contact.bday      = xml['bd']
      contact.nick_name = xml['nn']
      if co = xml['co']
        contact.company = Company.find_or_new({:given_name => co})
      end
    end
    # элементы контакта
    ['phone','email','url','im','address','id_card','tag','comment','avatar'].each do |i|
      items = xml[i] || []
      items = [items] unless items.is_a? Array
      items.each do |item|
        if i == 'tag'
          unless contact.tags.find(:first, :conditions => {:name => item})
            object = ContactTag.find_or_create(:name => item)
          else
            object = nil
          end
        else
          object = const_get(i.camelcase).from_xml(item)
        end
        # здесь определим какое отношение: has_one или has_many
        if Contact.reflections[i.to_sym]
          contact.send(:"#{i}=", object) if object
        else
          contact.send(i.pluralize) << object if object
        end
      end
    end
    return contact
  end

  #-----------------------------------------------------------------------------
  # экспорт контакта в vCard
  def to_vcf
    s = "BEGIN:VCARD\nVERSION:3.0\n"
    gn = Vcf::esc(given_name)
    fn = Vcf::esc(family_name)
    an = Vcf::esc(additional_name)
    hp = Vcf::esc(pref)
    hs = Vcf::esc(suff)

    if is_a? Person
      gn_ = gn.blank? ? '' : gn + ' '
      fn_ = fn.blank? ? '' : fn + ' '
      an_ = an.blank? ? '' : an + ' '
      hp_ = hp.blank? ? '' : hp + ' '
      hs_ = hs.blank? ? '' : hs + ' '
      s += "N:#{fn};#{gn};#{an};#{hp};#{hs}\n"
      s += "FN:#{hp_}#{fn_}#{gn_}#{an_}#{hs_}".strip + "\n"
      s += "ORG:#{Vcf::esc(company.given_name) if company};\n"
      s += "BDAY:#{Vcf::esc(bday)}\n" unless bday.blank?
      s += "TITLE:#{Vcf::esc(title)}\n" unless title.blank?
      s += "NICKNAME:#{Vcf::esc(nick_name)}\n" unless nick_name.blank?
    else
      s += "N:;;;;\nFN:#{gn}\nORG:#{gn};\nX-ABShowAs:COMPANY\n"
    end

    n = 1
    [phones, emails, urls, ims, addresses, comments].each do |item|
      item.each { |i| s += i.to_vcf(n); n+=1 }
    end

    s += "CATEGORIES:#{tags.map{|t| Vcf::esc(t.name)}.join(',')}\n" if tags.any?
    s += avatar.to_vcf if avatar
    s += "END:VCARD\n"
    return s
  end

  #-----------------------------------------------------------------------------
  # импорт контакта из Vpim::Vcard
  def self.from_vcf card
    if card.company?
      # создаем компанию
      contact = Company.find_or_new({:given_name => card.name.fullname||''})
    else
      # создаем персону
      contact = Person.find_or_new({:given_name => card.name.given||'', :family_name => card.name.family||'', :additional_name => card.name.additional||''})
      contact.pref      = card.name.prefix
      contact.suff      = card.name.suffix
      contact.title     = card.title
      contact.bday      = card.birthday
      contact.nick_name = card.nickname
      if card.org and card.org.any? and not card.org[0].blank?
        contact.company = Company.find_or_new({:given_name => card.org[0]})
      end
    end

    # телефонные номера с типами
    card.telephones.each do |t|
      phone = Phone.new(:value => t)
      phone.type = PhoneType.find_or_create_trans(t.xablabel,
        t.location +
        t.capability +
        t.nonstandard +
        (t.preferred ? ['pref'] : []))
      contact.phones << phone
    end if card.telephones

    # электронные адреса с типами
    card.emails.each do |e|
      email = Email.new(:value => e)
      email.type = EmailType.find_or_create_trans(e.xablabel,
        e.location +
        [e.format] +
        e.nonstandard +
        (e.preferred ? ['pref'] : []))
      contact.emails << email
    end if card.emails

    # веб адреса с типами
    card.urls.each do |u|
      url = Url.new(:value => u.uri)
      url.type = UrlType.find_or_create_trans(u.xablabel, u.format.to_a)
      contact.urls << url
    end if card.urls

    # клиенты мгновенных сообщений
    card.ims.each do |i|
      im = Im.new(:value => i.value)
      im.type = ImType.find_or_create_trans(i.xablabel, i.type)
      im.protocol = ImProtocol.find_or_create(:name => i.protocol)
      contact.ims << im
    end if card.ims

    # адреса
    card.addresses.each do |a|
      addr = Address.new(
        :post_office_box  => a.pobox,
        :extended_address => a.extended,
        :street_address   => a.street,
        :region           => a.region,
        :locality         => a.locality,
        :postal_code      => a.postalcode,
        :country_name     => a.country)
      if card.geo
        addr.latitude  = card.geo[0]
        addr.longitude = card.geo[1]
      end
      addr.type = AddressType.find_or_create_trans(a.xablabel,
        a.location +
        a.delivery +
        a.nonstandard +
        (a.preferred ? ['pref'] : []))
      addr.set_blank_to_nil
      contact.addresses << addr
    end if card.addresses

    # categories в теги
    card.categories.each do |c|
      unless contact.tags.find(:first, :conditions => {:name => c})
        contact.tags << ContactTag.find_or_create(:name => c)
      end
    end if card.categories

    # notes в комменты
    notes = defined?(card.notes) ? card.notes : [card.note]
    notes.each do |n|
      next unless n
      contact.comments << Comment.for_user.new(:text => n)
    end if notes

    # фоты
    card.photos.each do |photo|
      contact.avatar = Avatar.from_str(photo.to_str)
    end if card.photos

    return contact
  end

  #-----------------------------------------------------------------------------
  # механизм динамического создания типа адреса: по заявке юристов
  def set_types_for items, type_names, protocol_names=[]
    send(items).each_with_index do |item, i|
      item.set_type(type_names[i], protocol_names[i])
    end
  end


private

  #-----------------------------------------------------------------------------
  def set_family_name
    self.family_name ||= given_name
  end

  #-----------------------------------------------------------------------------
  # здесь запрет на создание родителя (родителя можно только выбрать из
  # существующих контактов) и запрет перекресных ссылок (я не могу быть
  # родителем своих родителей)
  def check_parent
    p = self
    while p = p.parent
      if p.new_record? or p.id == id
        errors.add(:parent)
        return false
      end
    end
    return true
  end

  #-----------------------------------------------------------------------------
  def check_overflow
    if account.contacts.size >= account.tariff_plan.max_contacts
      errors.add(:given_name, I18n::t(:account_full_contacts))
      return false
    end
    return true
  end

end