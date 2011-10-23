class Address < ActiveRecord::Base
  include Vcf
  is_paranoid

  belongs_to :type,   :class_name => 'AddressType'
  belongs_to :owner,  :polymorphic => true

  before_create :dont_save_if_present
  before_update :destroy_empty
  after_destroy :destroy_unused_type

  #-----------------------------------------------------------------------------
  def empty?
    post_office_box.blank?         and
    extended_address.blank?        and
    region.blank?                  and
    locality.blank?                and
    postal_code.blank?             and
    country_name.blank?            and
    (!latitude  or latitude  == 0) and
    (!longitude or longitude == 0)
  end

  #-----------------------------------------------------------------------------
  def type_name
    type ? " <span class='type_name'>#{type.name}</span>" : ''
  end

  #-----------------------------------------------------------------------------
  def vcf_types
    type ? type.vcf_values : ''
  end

  #-----------------------------------------------------------------------------
  # экспорт в vCard-адрес
  def to_vcf item_num
    pb = Vcf::esc(post_office_box)
    ea = Vcf::esc(extended_address)
    sa = Vcf::esc(street_address)
    lo = Vcf::esc(locality)
    re = Vcf::esc(region)
    pc = Vcf::esc(postal_code)
    cn = Vcf::esc(country_name)
    s = "item#{item_num}.ADR:#{pb};#{ea};#{sa};#{lo};#{re};#{pc};#{cn}\n"
    s += type.xablabel(item_num) if type
    return s
  end

  #-----------------------------------------------------------------------------
  def to_xml ops={}
    level = ops[:level] || 0
    ws0 = '  ' * level
    ws1 = '  ' * (level + 1)
    s = "#{ws0}<address>\n"
    s += "#{ws1}<ty>#{type.name}</ty>\n" if type
    s += "#{ws1}<pb>#{post_office_box}</pb>\n" unless post_office_box.blank?
    s += "#{ws1}<ea>#{extended_address}</ea>\n" unless extended_address.blank?
    s += "#{ws1}<sa>#{street_address}</sa>\n" unless street_address.blank?
    s += "#{ws1}<lo>#{locality}</lo>\n" unless locality.blank?
    s += "#{ws1}<re>#{region}</re>\n" unless region.blank?
    s += "#{ws1}<pc>#{postal_code}</pc>\n" unless postal_code.blank?
    s += "#{ws1}<cn>#{country_name}</cn>\n" unless country_name.blank?
    s += "#{ws1}<lt>#{latitude}</lt>\n" unless latitude.blank?
    s += "#{ws1}<ln>#{longitude}</ln>\n" unless longitude.blank?
    s += "#{ws0}</address>\n"
    return s
  end

  #-----------------------------------------------------------------------------
  def self.from_xml xml
    addr = new(
      :post_office_box  => xml['pb'],
      :extended_address => xml['ea'],
      :street_address   => xml['sa'],
      :region           => xml['re'],
      :locality         => xml['lo'],
      :postal_code      => xml['pc'],
      :country_name     => xml['cn'],
      :latitude         => xml['lt'],
      :longitude        => xml['ln'])
    addr.type = AddressType.find_or_create(:name => xml['ty'])
    return addr
  end

  #-----------------------------------------------------------------------------
  def to_s
    s = ''
    s += "#{country_name}, " unless country_name.blank?
    s += "#{postal_code}, " unless postal_code.blank?
    s += "#{region}, " unless region.blank?
    s += "#{locality}, " unless locality.blank?
    s += "#{street_address}, " unless street_address.blank?
    s = s[0..-3]
    s += type_name
    return s
  end

  #-----------------------------------------------------------------------------
  # механизм динамического создания типа адреса: по заявке юристов
  def set_type name, _nil=nil
    return if type_id
    return if name.blank?
    self.type = AddressType.find_or_create(:name => name)
    save unless new_record?
  end

  def fields_for_crc
    [ :post_office_box,
      :extended_address,
      :street_address,
      :region,
      :locality,
      :postal_code,
      :country_name,
      :latitude,
      :longitude]
  end

  #-----------------------------------------------------------------------------
  # выставляет пустые аттрибуты в null
  def set_blank_to_nil
    attributes.each_pair { |k,v| send(:"#{k}=",nil) if v.blank? }
    self
  end


private

  #-----------------------------------------------------------------------------
  def destroy_empty
    destroy if empty?
  end

  #-----------------------------------------------------------------------------
  def dont_save_if_present
    owner.addresses.find(:first, :conditions => {:crc => new_crc}).nil?
  end

  #-----------------------------------------------------------------------------
  # "реальное" удаление типа адреса, если ссылок на него больше нет
  def destroy_unused_type
    AddressType.delete(type_id) if type and type.addresses.count == 0
  end

end
