class CreateTagsRels < ActiveRecord::Migration
  def change
    create_table :tags_rels do |t|
      t.integer   :tag_id
      t.integer   :owner_id
      t.string    :owner_type
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
  end
end


