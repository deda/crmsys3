class ContactTag < Tag

  has_many :owners, :through => :tags_rels, :source_type => 'Contact'

end
