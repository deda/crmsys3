class CreateAttachmends < ActiveRecord::Migration
  def change
    create_table :attachmends do |t|
      t.integer   :account_id
      t.integer   :user_id
      t.integer   :owner_id
      t.string    :owner_type
      t.integer   :position
      t.string    :object_file_name
      t.integer   :object_file_size
      t.string    :object_content_type
      t.datetime  :object_updated_at
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
  end
end


