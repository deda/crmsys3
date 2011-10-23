class SaleTag < Tag

  has_many :owners, :through => :tags_rels, :source_type => 'Sale'

end
