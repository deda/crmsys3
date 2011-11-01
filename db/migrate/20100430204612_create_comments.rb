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
      t.index     [:user_id, :account_id]
      t.index     :account_id
      t.index     [:owner_id, :owner_type]
      t.index     :owner_type
      t.index     :deleted_at
      t.index     :crc
    end
  end
end
