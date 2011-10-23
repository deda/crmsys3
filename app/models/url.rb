class Url < ContactItem

  belongs_to :type, :class_name => 'UrlType'

  #-----------------------------------------------------------------------------
  # возвращает url с идентификатором протокола
  def url
    return value if value.index(/^\w+:\/\//)
    return 'http://' + value
  end

  #-----------------------------------------------------------------------------
  # возвращает url без идентификатора протокола
  def path
    return value.sub(/^\w+:\/\//, '')
  end

  #-----------------------------------------------------------------------------
  # возвращает строку html ссылки <a>...</a>
  def to_s
    "<a href='#{url}' target='_blank' style='font-size:100%'>#{path}</a> #{type_name}"
  end

end
