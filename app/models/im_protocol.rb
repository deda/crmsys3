class ImProtocol < Type

  has_many :ims, :foreign_key => :protocol_id

end
