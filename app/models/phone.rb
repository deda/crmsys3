class Phone < ContactItem

  belongs_to :type, :class_name => 'PhoneType'

end
