class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.integer   :owner_id
      t.string    :owner_type
      t.integer   :position
      t.string    :photo_file_name
      t.integer   :photo_file_size
      t.string    :photo_content_type
      t.datetime  :photo_updated_at
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
    add_index :images, [:owner_id, :owner_type]
    add_index :images, :owner_type
  end
end
