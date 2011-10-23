class TaskTag < Tag

  has_many :owners, :through => :tags_rels, :source_type => 'Task'

end
