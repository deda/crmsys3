class Email < ContactItem

  belongs_to :type, :class_name => 'EmailType'

  #-----------------------------------------------------------------------------
  def to_s
    "<a href=mailto:#{value}>#{value}</a>#{type_name}"
  end

end
