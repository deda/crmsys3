class Avatar < Image

  #-----------------------------------------------------------------------------
  def to_xml ops={}
    return "#{'  '*(ops[:level]||0)}<avatar>#{encoded_photo}</avatar>\n"
  end

end