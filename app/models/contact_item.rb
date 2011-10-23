class ContactItem < ActiveRecord::Base
  is_paranoid

  belongs_to :contact
  belongs_to :type

  validates_presence_of :value, :on => :create

  before_create :dont_save_if_present
  before_update :destroy_empty
  after_destroy :destroy_unused_type


  #-----------------------------------------------------------------------------
  def empty?
    value.blank?
  end

  #-----------------------------------------------------------------------------
  def type_name
    type ? " <span class='type_name'>#{type.name}</span>" : ''
  end

  #-----------------------------------------------------------------------------
  def to_s
    "#{value}#{type_name}"
  end

  #-----------------------------------------------------------------------------
  def to_vcf item_num
    vc_name = {'Phone'=>'TEL','Email'=>'EMAIL','Url'=>'URL'}[self.class.name]
    s = "item#{item_num}.#{Vcf::esc(vc_name)}:#{Vcf::esc(value)}\n"
    s += type.xablabel(item_num) if type
    return s
  end

  #-----------------------------------------------------------------------------
  def to_xml ops={}
    level = ops[:level] || 0
    cn  = self.class.name.underscore
    ws0 = '  ' * level
    ws1 = '  ' * (level + 1)
    s = "#{ws0}<#{cn}>\n#{ws1}<va>#{value}</va>\n"
    s += "#{ws1}<ty>#{type.name}</ty>\n" if type
    s += "#{ws1}<pr>#{protocol.name}</pr>\n" if defined?(protocol) and protocol
    s += "#{ws0}</#{cn}>\n"
    return s
  end

  #-----------------------------------------------------------------------------
  def self.from_xml xml
    item = new(:value => xml['va'])
    item.type = item.type_model.find_or_create(:name => xml['ty'])
    item.protocol = item.protocol_model.find_or_create(:name => xml['pr']) if defined?(item.protocol)
    return item
  end

  #-----------------------------------------------------------------------------
  def fields_for_crc
    [:protocol_id, :value]
  end

  #-----------------------------------------------------------------------------
  # механизм динамического создания типа элемента контакта
  def set_type type_name, protocol_name
    need_save = false
    if not type_id and not type_name.blank?
      self.type = type_model.find_or_create(:name => type_name)
      need_save = true
    end
    if not protocol_name.blank? and not protocol_id
      self.protocol = protocol_model.find_or_create(:name => protocol_name)
      need_save = true
    end
    save if need_save and not new_record?
  end

  #-----------------------------------------------------------------------------
  def type_model
    Object.const_get(:"#{self.class.name}Type")
  end
  #-----------------------------------------------------------------------------
  def protocol_model
    Object.const_get(:"#{self.class.name}Protocol")
  end


private

  #-----------------------------------------------------------------------------
  def destroy_empty
    destroy if empty?
  end

  #-----------------------------------------------------------------------------
  def dont_save_if_present
    contact.
      send(:"#{self.class.name.pluralize.underscore}").
      find(:first, :conditions => {:crc => new_crc}).
      nil?
  end

  #-----------------------------------------------------------------------------
  # "реальное" удаление типа адреса, если ссылок на него больше нет
  def destroy_unused_type
    type_model.delete(type_id) if type_id and type.contact_items.count == 0
    if defined?(protocol) and protocol
      protocol_model.delete(protocol_id) if protocol.ims.count == 0
    end
  end

end
