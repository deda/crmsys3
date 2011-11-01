class CreateInventoryItems < ActiveRecord::Migration
  def change
    create_table :inventory_items do |t|
      t.integer   :account_id       # Аккаунт
      t.integer   :user_id          # Пользователь
      t.integer   :owner_id
      t.string    :owner_type
      t.string    :name             # Наименование
      t.integer   :number_of_sheets # Количество листов
      t.integer   :position
      t.datetime  :created_at
      t.datetime  :updated_at
    end
  end
end
