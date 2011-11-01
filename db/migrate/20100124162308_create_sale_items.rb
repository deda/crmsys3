class CreateSaleItems < ActiveRecord::Migration
  def change
    # Таблица "Позиция спецификации" (продажа/покупка)
    create_table :sale_items do |t|
      t.integer     :sale_id          # к какой продаже/покупке относится эта позиция
      t.integer     :ware_item_id     # что и с какого склада продавали/покупали
      t.decimal     :quantity,        # кол-во проданного/купленного
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.integer     :discount_id      # примененная скида
      t.decimal     :discount_value,  # значение скидки в %
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.decimal     :price_in,        # = ware.price_in(на момент совершения сделки)
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.decimal     :price_out,       # = ware.price_out(на момент совершения сделки)
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.decimal     :price_discount,  # = price_out * (1 - discount_value / 100)
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.decimal     :price_total,     # = price_discount * quantity
        :precision  => 12,
        :scale      => 2,
        :default    => 0
      t.datetime  :created_at
      t.datetime  :updated_at
      t.datetime  :deleted_at
    end
  end
end
