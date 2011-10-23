class Tag < Type

  has_many :tags_rels

  validates_presence_of :name, :on => :create

  #-----------------------------------------------------------------------------
  def empty?
    name.blank?
  end

  #-----------------------------------------------------------------------------
  def self.string_for item
    s = ''
    tags = item.tags
    if tags.any?
      s += '<div class="tag">'
      tags.each { |tag| s +="<a href='#' class='tag rounded'>#{tag.name}</a> " }
      s += '</div>'
    end
    return s
  end

  #-----------------------------------------------------------------------------
  def to_xml ops={}
    return '' if name.blank?
    level = ops[:level] || 0
    ws0 = '  ' * level
    s = "#{ws0}<tag>#{name}</tag>\n"
    return s
  end

end
