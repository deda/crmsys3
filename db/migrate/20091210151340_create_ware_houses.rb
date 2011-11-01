class CreateWareHouses < ActiveRecord::Migration
  def change
    create_table :ware_houses do |t|
      t.integer   :account_id
      t.integer   :user_id
      t.string    :name
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
  end
end
