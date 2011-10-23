class TagsRel < ActiveRecord::Base

  belongs_to :tag
  belongs_to :owner, :polymorphic => true

end
