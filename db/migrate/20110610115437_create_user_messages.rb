class CreateUserMessages < ActiveRecord::Migration
  def change
    create_table :user_messages do |t|
      t.integer   :account_id
      t.integer   :user_id
      t.integer   :recipient_id
      t.integer   :forum_id
      t.integer   :theme_id
      t.integer   :parent_id
      t.string    :title
      t.text      :text
      t.datetime  :viewed_at
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
  end
end
