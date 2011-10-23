class AddressType < Type

  has_many :addresses, :foreign_key => :type_id

end
