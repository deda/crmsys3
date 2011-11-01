class CreateWareMovements < ActiveRecord::Migration
  def change
    # перемещения товара по складам
    create_table :ware_movements do |t|
      t.integer   :user_id        # кто (какой менеджер) создал это перемещение
      t.integer   :ware_id        # какой товар перемещаем
      t.integer   :from_id        # с какого склада перемещаем
      t.integer   :to_id          # на какой склад перемещаем
      t.integer   :sale_item_id   # какой позицией спецификации инициировано это перемещение
      t.decimal   :quantity,      # сколько перемещаем
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.integer   :state,         # состояние перемещения
        :default    => 0
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
  end
end
