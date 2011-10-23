class CaseTag < Tag

  has_many :owners, :through => :tags_rels, :source_type => 'Case'

end
