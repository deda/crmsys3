class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.integer   :account_id
      t.integer   :user_id
      t.integer   :owner_id
      t.string    :owner_type
      t.text      :text
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
      t.string    :crc
    end
    add_index :comments, [:user_id, :account_id]
    add_index :comments, :account_id
    add_index :comments, [:owner_id, :owner_type]
    add_index :comments, :owner_type
    add_index :comments, :deleted_at
    add_index :comments, :crc
  end
end
