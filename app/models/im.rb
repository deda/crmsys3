class Im < ContactItem

  belongs_to :type,     :class_name => 'ImType'
  belongs_to :protocol, :class_name => 'ImProtocol'

  def to_s
    "<span class='protocol_name'>#{protocol.name if protocol}:</span> #{value}#{type_name}"
  end

  #-----------------------------------------------------------------------------
  def to_vcf item_num
    vc_name = 'X-JABBER'
    vc_protocol = ''
    vc_item = "item#{item_num}"
    if protocol
      pn = protocol.name
      pu = pn.upcase
      if ['AIM','ICQ','MSN','JABBER','SKYPE','YAHOO'].include?(pu)
        vc_name = "X-#{pu}"
      else
        vc_protocol = "#{vc_item}.X-IMProtocol:#{Vcf::esc(pn)}\n" unless pn.blank?
      end
    end
    s = "#{vc_item}.#{vc_name}:#{Vcf::esc(value)}\n" + vc_protocol
    s += type.xablabel(item_num) if type
    return s
  end


end
