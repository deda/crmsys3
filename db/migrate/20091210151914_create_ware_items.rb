class CreateWareItems < ActiveRecord::Migration
  def change
    create_table :ware_items do |t|
      t.integer   :ware_id            # какой товар
      t.integer   :ware_house_id      # на каком складе
      t.decimal   :quantity,          # в каком кол-ве
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.decimal   :minimum,           # минимальный остаток данного товара на данном складе
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
  end
end
